class Scrum2bIssuesController < ApplicationController
  unloadable

  before_filter :find_project, :only => [:index,:board]
  before_filter :set_status_settings
  #layout false
  self.allow_forgery_protection = false
  def index
    @list_versions_open = @project.versions.where(:status => "open")
    @list_versions_closed = @project.versions.where(:status => "closed")

    if params[:session]
      session[:view_issue] = params[:session]
    end
    if  session[:view_issue] == "board"
      redirect_to :action => "board" ,:project_id =>  params[:project_id]
    else
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
  end

  def board
    if params[:session]
    session[:view_issue] = params[:session]
    end
    @list_versions_open = @project.versions.where(:status => "open")
    @list_versions_closed = @project.versions.where(:status => "closed")
    @member = @project.assignable_users
    @id_version  = params[:select_version]
    @select_issues  = params[:select_member]

    if @id_version
      if @id_version == "all"
        @issues_version =  @project.issues
      elsif
      @issues_version =  @project.issues.where(:fixed_version_id  => @id_version);
      end
    elsif
    @issues_version =  @project.issues
    end
    if @select_issues

      if @select_issues == "all"
        @issues_select =  @issues_version

      elsif @select_issues == "me"
        @issues_select =  @issues_version.where(:assigned_to_id => User.current.id )

      else
        @issues_select = @issues_version.where(:assigned_to_id => @select_issues)
      end

    else
      @issues_select =  @issues_version
    end
    @issues_new = @issues_select.where(:status_id => @default_not_start_status_id.to_i)
    @issues_start = @issues_select.where(:status_id => @default_inprogress_status_id.to_i)
    @issues_completed = @issues_select.where(:status_id => @default_completed_status_id.to_i)
    e = 0
    @issues_start.each do |issue_position|
      unless issue_position.position
        issue_position.update_attribute(:position,e)
      e = e+1
      end
    end
    @issues_started = @issues_select.where(:status_id => @default_inprogress_status_id.to_i).order(:position)
  end

  def update_status
    @project =  Project.find(params[:project_id])

    if params[:status] == "completed"
      @issue = @project.issues.find(params[:issue_id])
      @issue.update_attribute(:done_ratio,100)
      @issue.update_attribute(:status_id,@default_completed_status_id.to_i)

    end
    if params[:status] == "started"
      @issue = @project.issues.find(params[:issue_id])
      @issue.update_attribute(:status_id,@default_inprogress_status_id.to_i)

    end
    if params[:status] == "new"
      @issue = @project.issues.find(params[:issue_id])
      @issue.update_attribute(:status_id,@default_not_start_status_id.to_i)

    end
  end

  def sort_issues
    @position = params[:position]
    Rails.logger.info "Test_PARAMS POSITION #{params[:position].to_s}"
    @project = Project.find(params[:project_id])
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:position,@position.to_i)
    @sort_issue = @project.issues.where("status_id = ? AND position >= ?", @default_inprogress_status_id.to_i, @position.to_i)
    Rails.logger.info "Test_PARAMS ISSUES_POSITION #{@issue.position.to_s}"
    e = params[:position].to_i+1
    @sort_issue.each do |sort|
    		unless sort.id == @issue.id
    		sort.update_attribute(:position,e)
    	end
    	 e = e+1
    end
  end

  def ajax
    @project =  Project.find(params[:project_id])
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:done_ratio, params[:done_ratio])

  end

  def close_issue
    @project =  Project.find(params[:project_id])
    test= Array.new
    test = params[:issue_id]
    @int_array = test.split(',').collect(&:to_i)
    Rails.logger.info "HASH ARRAY #{test.to_s}"
    @issues = @project.issues.where(:id => @int_array)
    Rails.logger.info "TEST_ISSUE: #{@issues.to_s}"
    @issues.each do |issues|
      issues.update_attribute(:status_id,@default_closed_status_id.to_i)
    end
  end

  def edit_issue
    @project =  Project.find(params[:project_id])
    @issue = @project.issues.find(params[:id_issue])
    @issue.update_attribute(:subject,params[:subject])
    @issue.update_attribute(:assigned_to_id,params[:assignee])
    @issue.update_attribute(:estimated_hours,params[:est_time])
    @issue.update_attribute(:description,params[:description])
    @issue.update_attribute(:start_date,params[:date_start])
    @issue.update_attribute(:due_date,params[:date_end])
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
