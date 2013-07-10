class Scrum2bIssuesController < ApplicationController
  unloadable
  before_filter :find_project, :only => [:index, :board, :update, :update_status, :update_progress, :create, :change_sprint, :close]
  before_filter :set_status_settings
  
  self.allow_forgery_protection = false
  
  DEFAULT_STATUS_IDS = {}
  STATUS_IDS = {'status_no_start' => [].to_set, 'status_inprogress' => [].to_set, 
                       'status_completed' => [].to_set, 'status_closed' => [].to_set}

  SELECT_ISSUE_OPTIONS = {:all_working => 1,
                          :my => 2, 
                          :my_completed => 3, 
                          :new => 4, 
                          :completed => 5,
                          :closed => 6,
                          :all => 7,}
    
  def index
    if session[:view_issue].nil? || session[:view_issue] == "board" && (params[:switch_screens] || "").blank?
      redirect_to :action => "board" ,:project_id =>  params[:project_id]
      return
    end
    session[:view_issue] = "list"

    # Load Screen Fields
    @status_new = STATUS_IDS['status_no_start']
    @status_inprogress = STATUS_IDS['status_inprogress']
    @status_completed = STATUS_IDS['status_completed']
    @status_closed = STATUS_IDS['status_closed']
    @select_issue_options = SELECT_ISSUE_OPTIONS
    @list_versions_open = opened_versions_list #mount the selection list of versions
    @list_versions_parent_open = opened_shared_versions_list
    @list_versions_closed = closed_versions_list #mount the selection list of versions
    @list_versions_parent_closed = closed_shared_versions_list
    @id_member = @project.assignable_users.collect{|id_member| id_member.id}

    # Get session parameters
    session[:view_issue] = params[:session] if params[:session]
    select_issues  = (params[:select_issue] || "0").to_i 
    id_version  = params[:select_version]

    # Filter the issues search by SCRUM Status
  
    if select_issues == SELECT_ISSUE_OPTIONS[:new]
      all_backlog_status = STATUS_IDS['status_no_start'].dup
    elsif select_issues == SELECT_ISSUE_OPTIONS[:completed] || select_issues == SELECT_ISSUE_OPTIONS[:my_completed]
      all_backlog_status = STATUS_IDS['status_completed'].dup
    elsif select_issues == SELECT_ISSUE_OPTIONS[:closed] 
      all_backlog_status = STATUS_IDS['status_closed'].dup
    elsif select_issues == SELECT_ISSUE_OPTIONS[:all_working]
      all_backlog_status = STATUS_IDS['status_no_start'].dup
      all_backlog_status.merge(STATUS_IDS['status_inprogress'].dup)
      all_backlog_status.merge(STATUS_IDS['status_completed'].dup)
    else 
      all_backlog_status = STATUS_IDS['status_no_start'].dup
      all_backlog_status.merge(STATUS_IDS['status_inprogress'].dup)
      all_backlog_status.merge(STATUS_IDS['status_completed'].dup)
      all_backlog_status.merge(STATUS_IDS['status_closed'].dup)
    end
    issues = Issue.where(status_id: all_backlog_status.to_a)
    Rails.logger.info("all_backlog_status")
    Rails.logger.info(all_backlog_status.to_a)
    # Filter my issues 
    if select_issues == SELECT_ISSUE_OPTIONS[:my] || select_issues == SELECT_ISSUE_OPTIONS[:my_completed]
        issues =  issues.where(:assigned_to_id => User.current.id)
    end
    # Filter the issues by version
    if !id_version || id_version == "all" || id_version == "version_working"
      version = opened_versions_list.pluck(:id)
      if id_version == "all"
        version.concat(closed_versions_list.pluck(:id))
      end
    else  
      version =  id_version
    end

    @issues_backlog = issues.where(fixed_version_id: version).order("fixed_version_id DESC, status_id ASC, id ASC")
  end
  
  # Method to mount the versions selection list
  # merge the project versions opened and the project parent versions opened with sharing
  def opened_versions_list
    find_project unless @project
    return Version.where(status:"open").where(project_id: [@project.id,@project.parent_id])
  end

  def opened_project_versions_list
    find_project unless @project
    return @project.versions.where(:status => "open")
  end
 
  def opened_shared_versions_list
    find_project unless @project
    if @project.parent then
      return @project.parent.versions.where(:status => "open").where("sharing <> (?)","none")
    else
      return []
    end
  end

  def closed_versions_list 
    find_project unless @project
    return Version.where(status:"closed").where(project_id: [@project.id,@project.parent_id])
  end

  def closed_project_versions_list
    find_project unless @project
    return @project.versions.where(:status => "closed")
  end
 
  def closed_shared_versions_list
    find_project unless @project
    if @project.parent then
      return @project.parent.versions.where(:status => "closed").where("sharing <> (?)","none")
    else
      return []
    end
  end

# This method controls the actions on Board Screen

  def board

    session[:view_issue] = "board"
    @issue = Issue.new
    @tracker = Tracker.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @priority = IssuePriority.all
    @member = @project.assignable_users
    @list_versions_open = opened_versions_list #mount the selection list of versions
    @list_versions_parent_open = opened_shared_versions_list
    @id_member = @member.collect{|id_member| id_member.id}
    id_version  = params[:select_version]
    selected_member  = params[:select_member]
    @sprints = opened_versions_list

    if !id_version || id_version == "all"
      versions = opened_versions_list
    else
      versions = [id_version]
    end

    issues_filtered_by_version = Issue.where(fixed_version_id: versions)
    
    if selected_member && selected_member == "me"
        issues_filtered_by_version_and_user = issues_filtered_by_version.where("assigned_to_id = '?'",User.current.id)
    elsif selected_member && selected_member.to_i != 0
        issues_filtered_by_version_and_user = issues_filtered_by_version.where("assigned_to_id = '?'",selected_member.to_i)
    else
      issues_filtered_by_version_and_user = issues_filtered_by_version
    end

    @new_issues = issues_filtered_by_version_and_user.where("status_id IN (?)" , STATUS_IDS['status_no_start']).order(:id)
    @started_issues = issues_filtered_by_version_and_user.where("status_id IN (?)" , STATUS_IDS['status_inprogress']).order(:id)
    @completed_issues = issues_filtered_by_version_and_user.where("status_id IN (?)" , STATUS_IDS['status_completed']).order(:id)
  end

  def update_status
    @issue = @project.issues.find(params[:issue_id])
    return unless @issue
    if params[:status] == "completed"
      #TODO: not optimize, please refactor
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
    #TODO: we should have return JSON data to close the Loading form
    render :json => {:result => "success", :new => "Success to update the progress",
                       :new_ratio => params[:done_ratio]}
  end

  def close
    @project =  Project.find(params[:project_id])
    array_id = Array.new
    array_id = params[:issue_id]
    @int_array = array_id.split(',').collect(&:to_i)
    @issues = Issue.where(:id => @int_array)
    @issues.each do |issues|
      issues.update_attribute(:status_id,DEFAULT_STATUS_IDS['status_closed'])
    end
  end

  def update
    @sprints = opened_versions_list
    @priority = IssuePriority.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @tracker = Tracker.all
    @id_version  = params[:select_version]
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id}
    @issue = Issue.find(params[:id_issue])
    @issue.update_attributes(:subject => params[:subject], 
                             :assigned_to_id => params[:assignee],
                             :estimated_hours => params[:time],
                             :description => params[:description], 
                             :start_date => params[:date_start], 
                             :due_date => params[:date_end], 
                             :tracker_id => params[:tracker])
    if @issue.valid? 
      data  = render_to_string(:partial => "/scrum2b_issues/show_issue", 
                               :locals => {:issue => @issue, :id_member => @id_member})
      edit  = render_to_string(:partial => "/scrum2b_issues/form_new", 
                               :locals => {:issue => @issue, :tracker => @tracker, :member => @member, :id_member => @id_member,
                                           :status => @status, :priority => @priority, :sprint => @sprint})
      render :json => {:result => "edit_success", :message => "Success to update the message",
                       :content => data, :edit_content => edit }
    else
      render :json => {:result => "failure", :message => @issue.errors.full_messages,
                       :content => data, :edit_content => edit }
    end
  end
  
  def create
    @sort_issue = @project.issues.where("status_id IN (?)", STATUS_IDS['status_no_start']) 
    @sprints = opened_versions_list
    @priority = IssuePriority.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @tracker = Tracker.all
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id}
    
    @issue = Issue.new(:subject => params[:subject], :description => params[:description], :tracker_id => params[:tracker],
                       :project_id => params[:project_id], :status_id => params[:status], :assigned_to_id => params[:assignee],
                       :priority_id => params[:priority], :fixed_version_id => params[:sprint], :start_date => params[:date_start],
                       :due_date => params[:date_end], :estimated_hours => params[:time], :author_id => params[:author],
                       :done_ratio => 0, :is_private => false, :lock_version => 0 )    
    
    if @issue.save
      data  = render_to_string(:partial => "/scrum2b_issues/board_issue", :locals => {:issue => @issue, :tracker => @tracker, :member => @member, :id_member => @id_member,
                                                                                      :status => @status, :priority => @priority, :sprint => @sprint})
      render :json => {:result => "create_success", :message => "Success to create the issue",
                       :content => data,:id => @issue.id}
    else
      render :json => {:result => "failure", :message => @issue.errors.full_messages}
    end
  end
  def change_sprint
    array_id= Array.new
    array_id = params[:issue_id]
    @int_array = array_id.split(',').collect(&:to_i)
    @issues = Issue.where(:id => @int_array)
    @issues.each do |issues|
      issues.update_attribute(:fixed_version_id,params[:new_sprint])
    end
    redirect_to '/scrum2b_issues/index'
  end

  private

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
        STATUS_IDS[column_name].add(setting) 
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
  
#  private
  
#    def resort_for_version(versions, issues)
#      sort_versions = {}
#      versions.each do |version|
#        if version.status == "open"
#          version_issues = []
#          issues.each do |issue|
#           version_issues << issue if issue.fixed_version_id == version.id
#          end
#          sort_by_status_issues = []    
#          version_issues.each do |issue|
#          sort_by_status_issues << issue if @status_inprogress.include?(issue.status_id.to_s)
#          end
#         
#          version_issues.each do |issue|
#           sort_by_status_issues << issue if @status_new.include?(issue.status_id.to_s)
#          end
#         
#          version_issues.each do |issue|
#           sort_by_status_issues << issue if @status_completed.include?(issue.status_id.to_s)
#          end
#         
#          version_issues.each do |issue|
#           sort_by_status_issues << issue if @status_closed.include?(issue.status_id.to_s)
#          end
#            sort_versions.merge!(version.name => sort_by_status_issues)
#        end
#      end 
#      versions.each do |version|
#        if version.status == "closed"
#          version_issues = []
#          issues.each do |issue|
#           version_issues << issue if issue.fixed_version_id == version.id
#          end
#          sort_by_status_issues = []    
#          version_issues.each do |issue|
#          sort_by_status_issues << issue if @status_inprogress.include?(issue.status_id.to_s)
#          end
         
#          version_issues.each do |issue|
#           sort_by_status_issues << issue if @status_new.include?(issue.status_id.to_s)
#          end
         
#          version_issues.each do |issue|
#           sort_by_status_issues << issue if @status_completed.include?(issue.status_id.to_s)
#          end
         
#          version_issues.each do |issue|
#           sort_by_status_issues << issue if @status_closed.include?(issue.status_id.to_s)
#          end
#          sort_versions.merge!(version.name => sort_by_status_issues)
#        end
#      end
#      return sort_versions
#    end  
end

