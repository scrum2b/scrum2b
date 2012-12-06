class Scrum2bIssuesController < ApplicationController
  unloadable

  before_filter :find_project, :only => [:index,:board]
  before_filter :set_status_settings
  
  #layout false
  self.allow_forgery_protection = false
  
  def index
    @list_versions_open = @project.versions.where(:status => "open")
    @list_versions_closed = @project.versions.where(:status => "closed") 
    @id_member = @project.assignable_users.collect{|id_member| id_member.id}

    session[:view_issue] = params[:session] if params[:session]
      
    if session[:view_issue] == "board"
      redirect_to :action => "board" ,:project_id =>  params[:project_id]
      return
    end
    
    #TODO: Duplicate code, please refactor it
    @list_versions = @project.versions.all
    @id_version  = params[:select_version]  
    @select_issues  = params[:select_issue]
    if @select_issues
      if @select_issues == "1"
        @issues =  @project.issues
      end
      if @select_issues == "2"
        @issues =  @project.issues.where(:assigned_to_id => User.current.id)
      end
      if @select_issues == "3"
        @issues =  @project.issues.where(:assigned_to_id => User.current.id , :status_id => @default_completed_status_id.to_i)
      end
      if @select_issues == "4"
        @issues =  @project.issues.where(:status_id => @default_not_start_status_id.to_i)
      end
      if @select_issues == "5"
        @issues =  @project.issues.where(:status_id => @default_completed_status_id.to_i )
      end
      if @select_issues == "6"
        @issues =  @project.issues.where(:status_id => @default_closed_status_id.to_i )
      end
      if @select_issues == "7"
        @issues =  @project.issues.where("status_id NOT IN (?)", @default_closed_status_id.to_i )
      end
    elsif
      @issues = @project.issues.where("status_id NOT IN (?)", @default_closed_status_id.to_i )
    end
    
    #TODO: Logic is not clear, please refactor it
    if @id_version
      if @id_version == "all"
        @version = @project.versions.all
      end
      if @id_version == "version_working"
        @version = @project.versions.where("status NOT IN (?)","closed")
      end
      if @id_version != "all" && @id_version != "version_working"
        @version = Version.where(:id => @id_version);
      end
    elsif
      @version = @project.versions.where("status NOT IN (?)","closed")
    end
    @issues_backlog = @project.issues.where(:fixed_version_id => nil).all

  end

  def board
    if params[:session]
      session[:view_issue] = params[:session]
    end

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
    
    if @id_version && @id_version != "all"
      @issues_version =  @project.issues.where(:fixed_version_id  => @id_version);
    else
      @issues_version =  @project.issues
    end
    
    if @select_issues && @select_issues == "me"
      @issues_select =  @issues_version.where(:assigned_to_id => User.current.id )
    elsif @select_issues && @select_issues != "all"
      @issues_select = @issues_version.where(:assigned_to_id => @select_issues)
    else
      @issues_select =  @issues_version
    end
    
    @issues_new = @issues_select.where(:status_id => @default_not_start_status_id.to_i)
    @issues_start = @issues_select.where(:status_id => @default_inprogress_status_id.to_i)
    @issues_completed = @issues_select.where(:status_id => @default_completed_status_id.to_i)
    
    #TODO: @Hung: review these codes to avoid bugs in sorting
    #issue_postion = 0
    #@issues_start.each do |issue_position|
    #  unless issue_position.position
    #    issue_position.update_attribute(:position, e)
    #    e = e + 1
    #  end
    #end
    @issues_started = @issues_select.where(:status_id => @default_inprogress_status_id.to_i).order(:position)
  end

  def update_status
    @project =  Project.find(params[:project_id])
    @issue = @project.issues.find(params[:issue_id])
    unless @issue
      
      return
    end
      
    if params[:status] == "completed"
      #TODO: not optimize, please refactor
      @issue.update_attribute(:done_ratio,100)
      @issue.update_attribute(:status_id,@default_completed_status_id.to_i)
    end

    if params[:status] == "started"
      @issue.update_attribute(:status_id,@default_inprogress_status_id.to_i)
    end

    if params[:status] == "new"
      @issue.update_attribute(:status_id,@default_not_start_status_id.to_i)
    end
  end

  def sort
    @position = params[:position]
    Rails.logger.info "Test_PARAMS POSITION #{params[:position].to_s}"
    @project = Project.find(params[:project_id])
    
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:position,@position.to_i)
    
    @sort_issue = @project.issues.where("status_id = ? AND position >= ?", @default_inprogress_status_id.to_i, @position.to_i)
    
    Rails.logger.info "Test_PARAMS ISSUES_POSITION #{@issue.position.to_s}"
    e = params[:position].to_i+1
    @sort_issue.each do |sort|
  		sort.update_attribute(:position, e) unless sort.id == @issue.id
  	  e += 1
    end
  end

  def update_progress
    @project = Project.find(params[:project_id])
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:done_ratio, params[:done_ratio])
    #TODO: we should have return JSON data to close the Loading form
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
      issues.update_attribute(:status_id, @default_closed_status_id.to_i)
    end
  end

  def update
    @project =  Project.find(params[:project_id])
    @issue = @project.issues.find(params[:id_issue])
    #@issue.update_attribute(:subject, params[:edit_subject])
    @issue.update_attributes(:subject => params[:subject], 
                             :assigned_to_id => params[:assignee],
                             :estimated_hours => params[:est_time],
                             :description => params[:description], 
                             :start_date => params[:date_start], 
                             :due_date => params[:date_end], 
                             :tracker_id => params[:tracker], 
                             :priority_id => params[:priority])
    #@issue.update_attribute(:fixed_version_id,params[:sprin])
    data  = render_to_string(:partial => "/scrum2b_issues/show_issue", :locals => {:issue => @issue})
    edit  = render_to_string(:partial => "/scrum2b_issues/edit_issue", :locals => {:issue => @issue})
    render :json => {:result => "success", :message => "Success to update the message",
                       :content => data, :edit_content => edit }
   # Rails.logger.info "Json data : #{data.to_s}"
  end

  def new
    @issue = Issue.new()
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

    @not_start_statuses_id = []
    if @settings['status_no_start']
      @settings['status_no_start'].each do |setting|
        @not_start_statuses_id.push(setting[0])
      end
      @default_not_start_status_id = @not_start_statuses_id[0]

    end

    @inprogress_statuses_id = []
    if @settings['status_inprogress'].each do |setting|
    @inprogress_statuses_id.push(setting[0])
    end
      @default_inprogress_status_id = @inprogress_statuses_id[0]
    end

    @completed_statuses_id = []
    if @settings['status_completed']
      @settings['status_completed'].each do |setting|
        @completed_statuses_id.push(setting[0])
      end
      @default_completed_status_id = @completed_statuses_id[0]
    end

    @closed_statuses_id = []
    if @settings['status_closed']
      @settings['status_closed'].each do |setting|
        @closed_statuses_id.push(setting[0])
      end
      @default_closed_status_id = @closed_statuses_id[0]
    end
  end
  

end
