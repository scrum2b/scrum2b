class Scrum2bIssuesController < ApplicationController
  unloadable
  before_filter :find_project, :only => [:index, :board, :update, :update_status, :update_progress, :create, :change_sprint, :close, :sort]
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
                          :all => 7,}
    
  def index
    if session[:view_issue].nil? || session[:view_issue] == "board" && (params[:switch_screens] || "").blank?
      redirect_to :action => "board" ,:project_id =>  params[:project_id]
      return
    end
    session[:view_issue] = "list"
    @status_new = STATUS_IDS['status_no_start']
    @status_inprogress = STATUS_IDS['status_inprogress']
    @status_completed = STATUS_IDS['status_completed']
    @status_closed = STATUS_IDS['status_closed']
    @select_issue_options = SELECT_ISSUE_OPTIONS
    @list_versions_open = @project.versions.where(:status => "open")
    @list_versions_closed = @project.versions.where(:status => "closed") 
    @id_member = @project.assignable_users.collect{|id_member| id_member.id}
    session[:view_issue] = params[:session] if params[:session]
    @list_versions = @project.versions.all
    params[:select_version] ||= default_version
    @select_issues  = (params[:select_issue] || "0").to_i 
    if @select_issues == SELECT_ISSUE_OPTIONS[:all]
      @issues =  @project.issues.order("status_id, s2b_position")
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:my]
      @issues =  @project.issues.where(:assigned_to_id => User.current.id).order("status_id, s2b_position")
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:my_completed]
     @issues =  @project.issues.where(:assigned_to_id => User.current.id).where("status_id IN (?)" , STATUS_IDS['status_completed']).order("status_id, s2b_position")
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:new]
      @issues =  @project.issues.where("status_id IN (?)" , STATUS_IDS['status_no_start']).order("status_id, s2b_position")
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:completed]
      @issues =  @project.issues.where("status_id IN (?)" , STATUS_IDS['status_completed']).order("status_id, s2b_position")
    elsif @select_issues == SELECT_ISSUE_OPTIONS[:closed]
      @issues =  @project.issues.where("status_id IN (?)" , STATUS_IDS['status_closed']).order("status_id, s2b_position")
    else
      @issues =  @project.issues.where("status_id NOT IN (?)", STATUS_IDS['status_closed']).order("status_id, s2b_position")
    end
    
    #TODO: Logic is not clear, please refactor it
     if @id_version && @id_version == "all"
        @version = @project.versions.order("created_on")
     elsif @id_version && @id_version != "version_working" && @id_version != "all"
        @version = Version.where(:id => @id_version).order("created_on")
     else
       @version = @project.versions.where("status NOT IN (?)","closed").order("created_on")
     end
    @sort_versions = resort_for_version(@version, @issues)
    @id_issues = @issues.collect{|id_issue| id_issue.id}
    @issues_backlog = @project.issues.where(:fixed_version_id => nil).where("id IN (?)",@id_issues).order("status_id, s2b_position")
  end

  def board
    @max_position_issue = @project.issues.maximum(:s2b_position).to_i+1
    @issue_no_position = @project.issues.where(:s2b_position => nil)
    @issue_no_position.each do |issue|
      issue.update_attribute(:s2b_position,@max_position_issue)
      @max_position_issue += 1
    end
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
    params[:select_version] ||= default_version
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
    @sort_issue = @project.issues.where("status_id IN (?)", STATUS_IDS['status_no_start']) 
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
                       :done_ratio => 0, :is_private => false, :lock_version => 0, :s2b_position => 1)    
    
    if @issue.save
      @sort_issue.each do |issue|
        issue.update_attribute(:s2b_position, issue.s2b_position.to_i+1) if issue.id != @issue.id
      end
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
    @issues = @project.issues.where(:id => @int_array)
    @issues.each do |issues|
    issues.update_attribute(:fixed_version_id,params[:new_sprint])
    end
    redirect_to '/scrum2b_issues/index'
  end

def default_version
    find_project unless @project
    versions = @project.versions.where("status = 'open' AND effective_date > ?", Date.today).order("effective_date ASC").limit(1)
    if versions.nil? or versions.empty?
       0
    else
       # TODO should not have to do an extra sort here, but just order in the database. For some reason, the .order at the end of the above statement does not appear to be working:(
       versions.sort{|x,y| x.effective_date <=> y.effective_date}.first.id
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
  
  private
  
    def resort_for_version(versions, issues)
      sort_versions = {}
      versions.each do |version|
        if version.status == "open"
          version_issues = []
          issues.each do |issue|
           version_issues << issue if issue.fixed_version_id == version.id
          end
          sort_by_status_issues = []    
          version_issues.each do |issue|
          sort_by_status_issues << issue if @status_inprogress.include?(issue.status_id.to_s)
          end
         
          version_issues.each do |issue|
           sort_by_status_issues << issue if @status_new.include?(issue.status_id.to_s)
          end
         
          version_issues.each do |issue|
           sort_by_status_issues << issue if @status_completed.include?(issue.status_id.to_s)
          end
         
          version_issues.each do |issue|
           sort_by_status_issues << issue if @status_closed.include?(issue.status_id.to_s)
          end
            sort_versions.merge!(version.name => sort_by_status_issues)
        end
      end 
      versions.each do |version|
        if version.status == "closed"
          version_issues = []
          issues.each do |issue|
           version_issues << issue if issue.fixed_version_id == version.id
          end
          sort_by_status_issues = []    
          version_issues.each do |issue|
          sort_by_status_issues << issue if @status_inprogress.include?(issue.status_id.to_s)
          end
         
          version_issues.each do |issue|
           sort_by_status_issues << issue if @status_new.include?(issue.status_id.to_s)
          end
         
          version_issues.each do |issue|
           sort_by_status_issues << issue if @status_completed.include?(issue.status_id.to_s)
          end
         
          version_issues.each do |issue|
           sort_by_status_issues << issue if @status_closed.include?(issue.status_id.to_s)
          end
          sort_versions.merge!(version.name => sort_by_status_issues)
        end
      end
      return sort_versions
    end  
end

