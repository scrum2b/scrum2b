class S2bIssuesController < S2bApplicationController
  
  before_filter :set_related_data => [:get_data]
  before_filter :set_issue, :only => [:destroy, :update, :update_status, :update_version, :update_progress, :get_files, :upload_file]
  
  before_filter lambda { validate_permission_for?(:edit) }, :only => [:index, :update]
  before_filter lambda { validate_permission_for?(:view) }, :only => [:index]

  def index
  end
  
  def get_data
    ActiveRecord::Base.include_root_in_json = false
    @versions =  opened_versions_list
    @priority = IssuePriority.all
    @tracker = @project.trackers
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @issues = opened_versions_list.first.fixed_issues
    @issues_backlog = Issue.where(:fixed_version_id => nil).where("project_id IN (?)",@hierarchy_project_ids)
    render :json => {:versions => @versions, :issues => @issues, :issues_backlog => @issues_backlog, :tracker => @tracker, :priority => @priority, :status => @status, :members => @members, :status_ids => DEFAULT_STATUS_IDS}
  end
  
  def get_issues_version
    version = Version.find(params[:version_id])
    @issues = version.fixed_issues # <- not too useful
    render :json => {:issues => @issues}
  end

  def get_issues_backlog
    @issues = version.fixed_issues # <- not too useful
    render :json => {:issues => @issues}
  end
  
  def create
    issue = Issue.new(Rails::VERSION::MAJOR >= 4 ? issue_params : params[:issue])
    if issue.save
      render :json => {:result => "create_success", :issue => issue}
    else
      render :json => {result: "error", message: issue.errors.full_messages}
    end
  end

  def destroy
    if @issue.present? && @issue.destroy
      render :json => {result: "success"}
    else
      render :json => {result: "error", message: @issue.nil? ? "Invalid Issue!" : @issue.errors.full_messages}
    end
  end

  def destroy_many
    check = true
    params[:array_issue].each do |issue_id|
      issue = Issue.find(issue_id.to_i)
      if issue.present?
        issue.destroy
      else
        check = false
      end
    end
    if check
      render :json => {result: "success"}
    else
      render :json => {result: "error", message: "Invalid Issue!"}
    end
  end

  def change_version_issues
    check = true
    params[:array_issue].each do |issue_id|
      issue = Issue.find(issue_id.to_i)
      if issue.present?
        issue.update_attribute(:fixed_version_id,  params[:version_id])
      else
        check = false
      end
    end

    if check
      render :json => {result: "success"}
    else
      render :json => {result: "error", message: "Invalid Issue!"}
    end
  end

  def change_status_issues
    Rails.logger.info "change_status_issues"
    check = true
    completed = false
    params[:array_issue].each do |issue_id|
      issue = Issue.find(issue_id.to_i)
      if issue.present?
        param = { status_id: params[:status_id]}
        issue.update_issue(param, STATUS_IDS )
        completed = true if issue.completed?(STATUS_IDS)
      else
        check = false
      end
    end

    if check
      render :json => { result: completed ? "update_success_completed" : "update_success" }
    else
      render :json => {result: "error", message: "Invalid Issue!"}
    end
  end

  def update
    if @issue.present? && Rails::VERSION::MAJOR >= 4 ? @issue.update_issue(issue_params, STATUS_IDS) : @issue.update_issue(params[:issue], STATUS_IDS)
      render :json => {result: @issue.completed?(STATUS_IDS) ? "update_success_completed" : "update_success", issue: @issue}
    else
      render :json => {result: "error", message: @issue.nil? ? "Invalid Issue!" : @issue.errors.full_messages}
    end
  end
  
  private

    def issue_params
      params.require(:issue).permit(:tracker_id, :subject, :author_id, :description, :due_date, :status_id, :project_id, :assigned_to_id, :priority_id, :fixed_version_id, :start_date, :done_ratio, :estimated_hours)
    end

end
