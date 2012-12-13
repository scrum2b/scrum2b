class Scrum2bIssuesController < ApplicationController
  unloadable

  before_filter :find_project, :only => [:index, :board, :update, :update_status, :update_progress, :create]
  before_filter :set_status_settings
  
  #layout false
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
                          :all => 7,}
    
  def index
    if session[:view_issue].nil? || session[:view_issue] == "board" && (params[:switch_screens] || "").blank?
      redirect_to :action => "board" ,:project_id =>  params[:project_id]
      return
    end
    session[:view_issue] = "list"

    @select_issue_options = SELECT_ISSUE_OPTIONS
    @list_versions_open = @project.versions.where(:status => "open")
    @list_versions_closed = @project.versions.where(:status => "closed") 
    @id_member = @project.assignable_users.collect{|id_member| id_member.id}

    session[:view_issue] = params[:session] if params[:session]
    
    #TODO: Duplicate code, please refactor it
    @list_versions = @project.versions.all
    @id_version  = params[:select_version]  
    @select_issues  = (params[:select_issue] || "0").to_i 
    
    if @select_issues == SELECT_ISSUE_OPTIONS[:all]
      @issues =  @project.issues
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:my]
      @issues =  @project.issues.where(:assigned_to_id => User.current.id)
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:my_completed]
      @issues =  @project.issues.where(:assigned_to_id => User.current.id).where("status_id IN (?)" , STATUS_IDS['status_completed'])
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:new]
      @issues =  @project.issues.where("status_id IN (?)" , STATUS_IDS['status_no_start'])
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:completed]
      @issues =  @project.issues.where("status_id IN (?)" , STATUS_IDS['status_completed'])
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:closed]
      @issues =  @project.issues.where("status_id IN (?)" , STATUS_IDS['status_closed'])
    else
      @issues = @project.issues.where("status_id NOT IN (?)", STATUS_IDS['status_closed'])
    end
    
    #TODO: Logic is not clear, please refactor it
     if @id_version && @id_version == "all"
        @version = @project.versions.all
     elsif @id_version && @id_version != "version_working" && @id_version != "all"
        @version = Version.where(:id => @id_version);
     else
       @version = @project.versions.where("status NOT IN (?)","closed")
     end
    
    @issues_backlog = @project.issues.where(:fixed_version_id => nil).all
  end

  def board
    session[:view_issue] = "board"
    @issue = Issue.new
    @tracker = Tracker.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @priority = IssuePriority.all
    @list_versions_open = @project.versions.where(:status => "open")
    @list_versions_closed = @project.versions.where(:status => "closed")
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id}
    @id_version  = params[:select_version]
    @select_issues  = params[:select_member]
    @sprints = @project.versions.where(:status => "open")
    
    conditions = ["(1=1)"]

    if @id_version && @id_version != "all"
      conditions[0] += " AND fixed_version_id = ? "
      conditions << @id_version
    end
    
    if @select_issues && @select_issues == "me"
      conditions[0] += " AND assigned_to_id = ?"
      conditions << User.current.id
    elsif @select_issues && @select_issues != "all" && @select_issues.to_i != 0
      conditions[0] += " AND assigned_to_id = ?"
      conditions << @select_issues.to_i
    end

    @new_issues = @project.issues.where(conditions).where("status_id IN (?)" , STATUS_IDS['status_no_start']).order(:s2b_position)
    @started_issues = @project.issues.where(conditions).where("status_id IN (?)" , STATUS_IDS['status_inprogress']).order(:s2b_position)
    @completed_issues = @project.issues.where(conditions).where("status_id IN (?)" , STATUS_IDS['status_completed']).order(:s2b_position)
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

  def sort
    @s2b_position = params[:s2b_position]
    @project = Project.find(params[:project_id])
    
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:s2b_position,@s2b_position.to_i)
    
    #TODO: redo the codes to allow sorting in every column
    @sort_issue = @project.issues.where("status_id = ? AND s2b_position >= ?", DEFAULT_STATUS_IDS['status_inprogress'], @s2b_position.to_i)
    #TODO: optimize code with more clear variable name
    e = params[:s2b_position].to_i+1
    @sort_issue.each do |sort|
  		sort.update_attribute(:s2b_position, e) unless sort.id == @issue.id
  	  e += 1
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
    test= Array.new
    test = params[:issue_id]
    @int_array = test.split(',').collect(&:to_i)
    @issues = @project.issues.where(:id => @int_array)
    @issues.each do |issues|
      issues.update_attribute(:status_id,DEFAULT_STATUS_IDS['status_closed'])
    end
  end

  def update
    @sprints = @project.versions.where(:status => "open")
    @priority = IssuePriority.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @tracker = Tracker.all
    @id_version  = params[:select_version]
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id}
    @issue = @project.issues.find(params[:id_issue])
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
    @sprints = @project.versions.where(:status => "open")
    @priority = IssuePriority.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @tracker = Tracker.all
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id}
    @issue = Issue.new(:subject => params[:subject], :description => params[:description], :tracker_id => params[:tracker],
                       :project_id => params[:project_id], :status_id => params[:status], :assigned_to_id => params[:assignee],
                       :priority_id => params[:priority], :fixed_version_id => params[:sprint], :start_date => params[:date_start],
                       :due_date => params[:date_end], :estimated_hours => params[:time], :author_id => params[:author],
                       :done_ratio => 0, :is_private => false, :lock_version => 0, :s2b_position => 0)    
    if @issue.save 
      data  = render_to_string(:partial => "/scrum2b_issues/board_issue", :locals => {:issue => @issue, :tracker => @tracker, :member => @member, :id_member => @id_member,
                                                                                      :status => @status, :priority => @priority, :sprint => @sprint})
      render :json => {:result => "create_success", :message => "Success to create the issue",
                       :content => data,:id => @issue.id}
    else
      render :json => {:result => "failure", :message => @issue.errors.full_messages}
    end
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
