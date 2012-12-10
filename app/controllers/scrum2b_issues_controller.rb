class Scrum2bIssuesController < ApplicationController
  unloadable

  before_filter :find_project, :only => [:index, :board, :update, :update_status, :update_progress]
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

    @tracker = Tracker.all
    @status = IssueStatus.all
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

    @new_issues = @project.issues.where(conditions).where("status_id IN (?)" , STATUS_IDS['status_no_start']).order(:position)
    @started_issues = @project.issues.where(conditions).where("status_id IN (?)" , STATUS_IDS['status_inprogress']).order(:position)
    @completed_issues = @project.issues.where(conditions).where("status_id IN (?)" , STATUS_IDS['status_completed']).order(:position)
  end

  def update_status
    @issue = @project.issues.find(params[:issue_id])
    return unless @issue

    if params[:status] == "completed"
      #TODO: not optimize, please refactor
      @issue.update_attributes(:done_ratio => 100, :status_id => DEFAULT_STATUS_IDS['status_completed'])
      render :json => {:status => "completed", :done_ratio => 100 }
    end

    if params[:status] == "started"
      @issue.update_attribute(:status_id, DEFAULT_STATUS_IDS['status_inprogress'])
    end

    if params[:status] == "new"
      @issue.update_attribute(:status_id, DEFAULT_STATUS_IDS['status_no_start'])
    end
  end

  def sort
    @position = params[:position]
    Rails.logger.info "Test_PARAMS POSITION #{params[:position].to_s}"
    @project = Project.find(params[:project_id])
    
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:position,@position.to_i)
    
    #TODO: redo the codes to allow sorting in every column
    @sort_issue = @project.issues.where("status_id = ? AND position >= ?", DEFAULT_STATUS_IDS['status_inprogress'], @position.to_i)
    
    Rails.logger.info "Test_PARAMS ISSUES_POSITION #{@issue.position.to_s}"
    #TODO: optimize code with more clear variable name
    e = params[:position].to_i+1
    @sort_issue.each do |sort|
  		sort.update_attribute(:position, e) unless sort.id == @issue.id
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
    Rails.logger.info "HASH ARRAY #{test.to_s}"
    @issues = @project.issues.where(:id => @int_array)
    Rails.logger.info "TEST_ISSUE: #{@issues.to_s}"
    @issues.each do |issues|
      issues.update_attribute(:status_id,DEFAULT_STATUS_IDS['status_closed'])
    end
  end

  def update
    @id_version  = params[:select_version]
    @tracker = Tracker.all
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id}
    @issue = @project.issues.find(params[:id_issue])
    @issue.update_attributes(:subject => params[:subject], 
                             :assigned_to_id => params[:assignee],
                             :estimated_hours => params[:est_time],
                             :description => params[:description], 
                             :start_date => params[:date_start], 
                             :due_date => params[:date_end], 
                             :tracker_id => params[:tracker])
    if @issue.valid? 
      data  = render_to_string(:partial => "/scrum2b_issues/show_issue", 
                               :locals => {:issue => @issue, :id_member => @id_member})
      edit  = render_to_string(:partial => "/scrum2b_issues/edit_issue", 
                               :locals => {:issue => @issue, :tracker => @tracker, :member => @member})
      render :json => {:result => "success", :message => "Success to update the message",
                       :content => data, :edit_content => edit }
    else
      render :json => {:result => "failure", :message => @issue.errors.full_messages,
                       :content => data, :edit_content => edit }
    end
  end

  def new
    @issue = Issue.new
    Rails.logger.info "TEST_ISSUE"
    edit  = render_to_string(:partial => "/scrum2b_issues/edit_issue", :locals => {:issue => @issue})
    render :json => {:edit_content => edit }
  end   
     
  def create
    #TODO: @Hung: refactor this codes
    #call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
    Rails.logger.info "TEST_ISSUE"
    @issue = Issue.new(params[:issue])
    respond_to do |format|
      if @issue.save
        flash[:notice] = "You have successfully to create the article"
        format.html { redirect_to "/" }
      else
        flash[:error] = "You have error to create the article"
      end
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
      Rails.logger.info "column_name #{column_name}"
      Rails.logger.info "@settings[key]: #{@settings[column_name].class.name} - #{@settings[column_name].to_s}"
      @settings[column_name].keys.each { |setting| 
        Rails.logger.info "setting: #{setting.to_s}"
        STATUS_IDS[column_name].push(setting) 
      } if @settings[column_name]
      
      
      Rails.logger.info "STATUS_IDS[key]: #{STATUS_IDS[column_name].to_s}"
      if STATUS_IDS[column_name].empty?
        need_to_resetting = true;
      else
        DEFAULT_STATUS_IDS[column_name] = STATUS_IDS[column_name].first
      end
      Rails.logger.info "DEFAULT_STATUS_IDS[column_name]: #{DEFAULT_STATUS_IDS[column_name]}"
    end
     
    if need_to_resetting
      flash[:notice] = "The system has not been setup to use Scrum2B Tool. Please contact to Administrator " + 
                       "or go to the Settings page of the plugin: <a href='/settings/plugin/scrum2b'>/settings/plugin/scrum2b</a> to config."
      redirect_to "/projects/#{@project.to_param}"
    end
  end

end
