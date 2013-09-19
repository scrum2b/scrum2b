class S2bBoardsController < ApplicationController
  unloadable
  before_filter :find_project, :only => [:index, :update, :update_status, :update_progress, :create, :sort,
                                         :close_on_board, :filter_issues_onboard, :opened_versions_list, :closed_versions_list]
  before_filter :set_status_settings
  before_filter :check_before_board, :only => [:index, :close_on_board, :filter_issues_onboard, :update, :create]
  skip_before_filter :verify_authenticity_token

  self.allow_forgery_protection = false
  
  DEFAULT_STATUS_IDS = {}
  STATUS_IDS = {'status_no_start' => [], 'status_inprogress' => [], 
                'status_completed' => [], 'status_closed' => []}
 
  def index
    #
    @max_position_issue = @project.issues.maximum(:s2b_position).to_i+1
    @issue_no_position = @project.issues.where(:s2b_position => nil)
    @issue_no_position.each do |issue|
      issue.update_attribute(:s2b_position, @max_position_issue)
      @max_position_issue += 1
    end
    
    session[:view_issue] = "board"
    
    #TODO: thua code 2 dong du
    @list_versions_open = opened_versions_list
    @list_versions_closed = closed_versions_list

    @new_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_no_start']).order(:s2b_position)
    @started_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_inprogress']).order(:s2b_position)
    @completed_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_completed']).order(:s2b_position)     
  end
  
  def update_status
    @issue = @project.issues.find(params[:issue_id])
    return unless @issue
    if params[:status] == "completed"
      @issue.update_attributes(:done_ratio => 100, :status_id => DEFAULT_STATUS_IDS['status_completed'])
      render :json => {:status => "completed", :done_ratio => 100 }
    elsif params[:status] == "started"
      @issue.update_attribute(:status_id, DEFAULT_STATUS_IDS['status_inprogress'])
    elsif params[:status] == "new"
      @issue.update_attribute(:status_id, DEFAULT_STATUS_IDS['status_no_start'])
    end
  end
  
  def update_progress
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:done_ratio, params[:done_ratio])
    #TODO: move message content to Location files
    render :json => {:result => "success", :new => "Success to update the progress",
                     :new_ratio => params[:done_ratio]}
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
  
  def close_on_board
    array_id= Array.new
    array_id = params[:issue_id]
    
    @int_array = array_id.split(',').collect(&:to_i)
    @issues = @project.issues.where(:id => @int_array)
    @issues.each do |issues|
      issues.update_attribute(:status_id,DEFAULT_STATUS_IDS['status_closed'])
    end
    
    @new_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_no_start']).order(:s2b_position)
    @started_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_inprogress']).order(:s2b_position)
    @completed_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_completed']).order(:s2b_position)   
    
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_boards/screen_board",
                                           :locals => {:id_member => @id_member , 
                                                       :completed_issues => @completed_issues,
                                                       :project => @project,
                                                       :new_issues => @new_issues,
                                                       :started_issues => @started_issues,
                                                       :tracker => @tracker,
                                                       :priority => @priority,
                                                       :member => @member,
                                                       :issue => @issue,
                                                       :status => @status,
                                                       :sprints => @sprints })
      }
    end
  end

  def update
    # Update attributes of issue from parameter
    @id_version  = params[:issue][:sprint]
    @issue = @project.issues.find(params[:issue][:id])
    @issue.update_attributes(params[:issue])
    
    if @issue.valid? 
      data  = render_to_string(:partial => "/s2b_boards/show_issue", 
                               :locals => {:issue => @issue, :id_member => @id_member})
      edit  = render_to_string(:partial => "/s2b_boards/form_new", 
                               :locals => {:issue => @issue, 
                                           :tracker => @tracker, 
                                           :member => @member, 
                                           :id_member => @id_member,
                                           :status => @status, 
                                           :priority => @priority, 
                                           :sprint => @sprint})
      render :json => {:result => "edit_success", :message => "Success to update the message",
                       :content => data, :edit_content => edit }
    else
      render :json => {:result => "failure", :message => @issue.errors.full_messages,
                       :content => data, :edit_content => edit }
    end
  end
  
  def create
    @sort_issue = @project.issues.where("status_id IN (?)", STATUS_IDS['status_no_start'])
    #Creat new issue
    @issue = Issue.new(params[:issue])
    if @issue.save
      @sort_issue.each do |issue|
        issue.update_attribute(:s2b_position, issue.s2b_position.to_i+1) if issue.id != @issue.id
      end
      data  = render_to_string(:partial => "/s2b_boards/board_issue", 
                               :locals => {:issue     => @issue, 
                                           :tracker   => @tracker, 
                                           :member    => @member, 
                                           :id_member => @id_member,
                                           :status    => @status, 
                                           :priority  => @priority, 
                                           :sprint    => @sprint})
      render :json => {:result => "create_success", :message => "Success to create the issue",
                       :content => data,:id => @issue.id}
    else
      render :json => {:result => "failure", :message => @issue.errors.full_messages}
    end
  end
  
  def filter_issues_onboard
    session[:params_select_version_onboard] = params[:select_version]
    session[:params_select_member] = params[:select_member]
    session[:conditions] = ["(1=1)"]
    if session[:params_select_version_onboard] && session[:params_select_version_onboard] != "all"
      session[:conditions][0] += " AND fixed_version_id = ? "
      session[:conditions] << session[:params_select_version_onboard]
    end
    if session[:params_select_member] && session[:params_select_member] == "me"
      session[:conditions][0] += " AND assigned_to_id = ?"
      session[:conditions] << User.current.id
    elsif session[:params_select_member] && session[:params_select_member] != "all" && session[:params_select_member].to_i != 0
      session[:conditions][0] += " AND assigned_to_id = ?"
      session[:conditions] << session[:params_select_member].to_i
    end
    @new_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_no_start']).order(:s2b_position)
    @started_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_inprogress']).order(:s2b_position)
    @completed_issues = @project.issues.where(session[:conditions]).where("status_id IN (?)" , STATUS_IDS['status_completed']).order(:s2b_position)
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_boards/screen_board",
                                           :locals => {:id_member => @id_member , 
                                                       :completed_issues => @completed_issues,
                                                       :project => @project,
                                                       :new_issues => @new_issues,
                                                       :started_issues => @started_issues,
                                                       :tracker => @tracker, 
                                                       :priority => @priority,
                                                       :member => @member,
                                                       :issue => @issue,
                                                       :status => @status,
                                                       :sprints => @sprints })
      }
    end
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
    Rails.logger.info "Test Params #{params[:issue]}"
    project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
    @project = Project.find(project_id)
  end

  def check_before_board
    @issue = Issue.new
    @priority = IssuePriority.all
    @tracker = Tracker.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @sprints = @project.versions.where(:status => "open")
    @project =  Project.find(params[:project_id])
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id}    
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
