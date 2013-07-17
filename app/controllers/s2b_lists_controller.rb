class S2bListsController < ApplicationController
  unloadable
  before_filter :find_project, :only => [:index, :change_sprint, :close_on_list, :sort,
                                         :filter_issues_onlist]
  before_filter :set_status_settings 
  before_filter :filter_issues_onlist, :only => [:index]
  skip_before_filter :verify_authenticity_token
  self.allow_forgery_protection = false
  
  DEFAULT_STATUS_IDS = {}
  STATUS_IDS = {'status_no_start' => [], 'status_inprogress' => [], 
                       'status_completed' => [], 'status_closed' => []}
  SELECT_ISSUE_OPTIONS = {:all_working => 1,
                          :my => 2, 
                          :my_completed => 3, 
                          :new => 4, 
                          :completed => 5,
                          :closed => 6,
                          :all => 7}
                          
  def index
    @select_issue_options = SELECT_ISSUE_OPTIONS
    @list_versions_open = opened_versions_list
    @list_versions_closed = closed_versions_list 
    @id_member = @project.assignable_users.collect{|id_member| id_member.id}
    @list_versions = @project.versions.all
  end
  
  
  def sort
    @max_position = @project.issues.where("status_id IN (?)", STATUS_IDS[params[:new_status]]).maximum(:s2b_position)
    @issue = @project.issues.find(params[:issue_id])
    @old_position = @issue.s2b_position
    if params[:id_next].to_i != 0
      @next_issue = @project.issues.find(params[:id_next].to_i) 
      @next_position = @next_issue.s2b_position
    end
    if params[:id_prev].to_i != 0
      @prev_issue = @project.issues.find(params[:id_prev].to_i)
      @prev_position = @prev_issue.s2b_position
    end
    if params[:new_status] != params[:old_status] && params[:id_next].to_i == 0 && params[:id_prev].to_i == 0
      
       @issue.update_attribute(:s2b_position,1)
    elsif params[:new_status] != params[:old_status] && params[:id_next].to_i == 0 && params[:id_prev].to_i != "" 
      @issue.update_attribute(:s2b_position,@max_position.to_i+1)
    elsif params[:new_status] != params[:old_status] && params[:id_next].to_i != 0 && params[:id_prev].to_i == 0
      @sort_issue = @project.issues.where("status_id IN (?)", STATUS_IDS[params[:new_status]])
      @sort_issue.each do |issue|
        issue.update_attribute(:s2b_position,issue.s2b_position.to_i+1) if issue.id != @issue.id
      end
      @issue.update_attribute(:s2b_position,1)
    elsif params[:new_status] != params[:old_status] && params[:id_next].to_i != 0 && params[:id_prev].to_i != 0
       @sort_issue = @project.issues.where("status_id IN (?) AND s2b_position >= ? ", STATUS_IDS[params[:new_status]],@next_position)

       @sort_issue.each do |issue|
        issue.update_attribute(:s2b_position,issue.s2b_position.to_i+1) if issue.id != @issue.id
      end
      @issue.update_attribute(:s2b_position,@next_position)
    elsif params[:new_status] == params[:old_status]
      if @prev_position && @old_position < @prev_position
        @sort_issue = @project.issues.where("status_id IN (?) AND s2b_position > ? AND s2b_position <= ? ", STATUS_IDS[params[:new_status]],@old_position,@prev_position)
        @sort_issue.each do |issue|
          issue.update_attribute(:s2b_position,issue.s2b_position.to_i-1) if issue.id != @issue.id
        end
        @issue.update_attribute(:s2b_position,@prev_position)   
      elsif @old_position > @next_position
        @sort_issue = @project.issues.where("status_id IN (?) AND s2b_position < ? AND s2b_position >= ? ", STATUS_IDS[params[:new_status]],@old_position,@next_position)
        @sort_issue.each do |issue|
          issue.update_attribute(:s2b_position,issue.s2b_position.to_i+1) if issue.id != @issue.id
        end
        @issue.update_attribute(:s2b_position,@next_position)
      end
    end
  end
  
  def change_sprint
    array_id= Array.new
    array_id = params[:issue_id]
    int_array = array_id.split(',').collect(&:to_i)
    issues = @project.issues.where(:id => int_array)
    issues.each do |issue|
      issue.update_attribute(:fixed_version_id,params[:new_sprint])
    end
    filter_issues_onlist
  end
  
  def filter_issues_onlist
    @sort_versions = {}
      if session[:view_issue].nil? || session[:view_issue] == "board" && (params[:switch_screens] || "").blank?
        redirect_to :controller => "s2b_boards", :action => "index" ,:project_id =>  params[:project_id]
        return
      end
    session[:view_issue] = "list"
    session[:param_select_version]  = (params[:select_version] || "version_working")
    session[:param_select_issues] = params[:select_issue].to_i if params[:select_issue]
    
    if session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:new]
      all_backlog_status = STATUS_IDS['status_no_start'].dup
    elsif session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:completed] || session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:my_completed]
      all_backlog_status = STATUS_IDS['status_completed'].dup
    elsif session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:closed] 
      all_backlog_status = STATUS_IDS['status_closed'].dup
    elsif !session[:param_select_issues] || session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:all_working]
      all_backlog_status = STATUS_IDS['status_no_start'].dup
      all_backlog_status.push(STATUS_IDS['status_inprogress'].dup)
      all_backlog_status.push(STATUS_IDS['status_completed'].dup)
    else 
      all_backlog_status = STATUS_IDS['status_no_start'].dup
      all_backlog_status.push(STATUS_IDS['status_inprogress'].dup)
      all_backlog_status.push(STATUS_IDS['status_completed'].dup)
      all_backlog_status.push(STATUS_IDS['status_closed'].dup)
    end
    @issues = Issue.where(status_id: all_backlog_status.to_a).order("status_id, s2b_position DESC")
    # Filter my issues 
    if session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:my] || session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:my_completed]
        @issues = @issues.where(:assigned_to_id => User.current.id)
    end
    if session[:param_select_version] && session[:param_select_version] == "all"
      versions = @project.versions.order("created_on")
    elsif session[:param_select_version] && session[:param_select_version] != "version_working" && session[:param_select_version] != "all"
      versions = Version.where(:id => session[:param_select_version]).order("created_on")
    else
      versions = @project.versions.where("status NOT IN (?)","closed").order("created_on")
    end
    versions.each do |version|
      @sort_versions[version] = @issues.where(fixed_version_id: version)
    end
    id_issues = @issues.collect{|id_issue| id_issue.id}
    @issue_backlogs = @project.issues.where(:fixed_version_id => nil).where("id IN (?)",id_issues).order("status_id, s2b_position")
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_lists/screen_list",:locals => {:sort_versions => @sort_versions,:issues_backlog => @issues_backlog})
      }
      format.html {}
    end
  end
  
  def close_on_list
    array_id= Array.new
    array_id = params[:issue_id]
    int_array = array_id.split(',').collect(&:to_i)
    issues = @project.issues.where(:id => int_array)
    issues.each do |issue|
      issue.update_attribute(:status_id,DEFAULT_STATUS_IDS['status_closed'])
    end
    filter_issues_onlist   
  end
  
  private
  
  def opened_versions_list
    find_project unless @project
    return Version.where(status:"open").where(project_id: [@project.id,@project.parent_id])
  end
  
  def closed_versions_list 
    find_project unless @project
    return Version.where(status:"closed").where(project_id: [@project.id,@project.parent_id])
  end
  
  def find_project
    # @project variable must be set before calling the authorize filter
    project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
    @project = Project.find(project_id)
  end
  
  def set_status_settings
    @plugin = Redmine::Plugin.find("scrum2b")
    @settings = Setting["plugin_#{@plugin.id}"]
    
    # Loop to set default of settings items
    need_to_resetting = false
    STATUS_IDS.keys.each do |column_name|
      @settings[column_name].keys.each { |setting| 
        STATUS_IDS[column_name].push(setting) 
      } if @settings[column_name]
      
      if STATUS_IDS[column_name].empty?
        need_to_resetting = true;
      else
        DEFAULT_STATUS_IDS[column_name] = STATUS_IDS[column_name].first
      end
    end
     
    if need_to_resetting
      flash[:notice] = "The system has not been setup to use Scrum2B Tool. Please contact to Administrator " + 
                       "or go to the Settings page of the plugin: <a href='/settings/plugin/scrum2b'>/settings/plugin/scrum2b</a> to config."
      redirect_to "/projects/#{@project.to_param}"
    end
  end
end
