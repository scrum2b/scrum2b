class S2bApplicationController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token
  before_filter :set_status_settings

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
        
  protected
  
  def opened_versions_list
    find_project unless @project
    return Version.where(:status => "open").where(:project_id => @hierarchy_project_id)
  end
  
  def closed_versions_list 
    find_project unless @project
    return Version.where(:status => "closed").where(:project_id => @hierarchy_project_id)
  end
  
  def find_project
    # @project variable must be set before calling the authorize filter
    project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
    @project = Project.find(project_id)
    User.current.roles_for_project(@project).each do |role|
      session[:roles_edit] = true ? role.permissions.include?(:s2b_edit_issue) : false
    end
    @hierarchy_project = Project.where(:parent_id => @project.id) << @project
    @hierarchy_project_id = @hierarchy_project.collect{|project| project.id}
  end
  
  def get_issues
    @issue_no_position = []     
    @issue_no_position = Issue.where(session[:conditions]).where("s2b_position IS NULL AND project_id IN (?)",@hierarchy_project_id)
    @new_issues = Issue.where(session[:conditions]).where("status_id IS NULL or status_id IN (?) AND project_id IN (?)" , STATUS_IDS['status_no_start'],@hierarchy_project_id).order(:s2b_position)
    @in_progress_issues = Issue.where(session[:conditions]).where("status_id IN (?) AND project_id IN (?)" , STATUS_IDS['status_inprogress'],@hierarchy_project_id).order(:s2b_position)
    @completed_issues = Issue.where(session[:conditions]).where("status_id IN (?) AND project_id IN (?)" , STATUS_IDS['status_completed'],@hierarchy_project_id).order(:s2b_position)            
    Rails.logger.info "SSSSSSSSSSSSSSSSSSSSSS#{@issue_no_position.to_a}"
  end

  def set_status_settings
    @plugin = Redmine::Plugin.find("scrum2b")
    @settings = Setting["plugin_#{@plugin.id}"]   
    # Loop to set default of settings items
    need_to_resetting = false
    STATUS_IDS.keys.each do |column_name|
      @settings[column_name].keys.each { |setting| 
        STATUS_IDS[column_name].push(setting.to_i) 
      } if @settings[column_name]
      
      if STATUS_IDS[column_name].empty?
        need_to_resetting = true;
      else
        DEFAULT_STATUS_IDS[column_name] = STATUS_IDS[column_name].first.to_i
      end
    end
     
    if need_to_resetting
      flash[:notice] = "The system has not been setup to use Scrum2B Tool. Please contact to Administrator " + 
                       "or go to the Settings page of the plugin: <a href='/settings/plugin/scrum2b'>/settings/plugin/scrum2b</a> to config."
      redirect_to "/projects/#{@project.to_param}"
    end
  end
end
