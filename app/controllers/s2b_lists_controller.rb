class S2bListsController < S2bApplicationController
  
  before_filter :filter_issues, :only => [:index]
  before_filter :get_members, :only => [:index]
  before_filter lambda { check_permission(:edit) }, :only => [:change_sprint, :change_sprint]
  before_filter lambda { check_permission(:view) }, :only => [:index, :filter_issues]               
  
  def index
    @select_issue_options = SELECT_ISSUE_OPTIONS
    @list_versions_open = opened_versions_list
    @list_versions_closed = closed_versions_list 
    @id_member = @members.collect{|id_member| id_member.id}
    @list_versions = Version.where(:project_id => @hierarchy_project_id).order("created_on")
  end
  
  def filter_issues
    @sort_versions = {}
    if session[:view_issue].nil? || session[:view_issue] == "board" && (params[:switch_screens] || "").blank?
      redirect_to :controller => "s2b_boards", :action => "index" ,:project_id =>  params[:project_id]
      return
    end
    
    session[:view_issue] = "list"
    session[:param_select_version]  = params[:select_version] if params[:select_version]
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
    
    issues = Issue.where(:status_id => all_backlog_status.to_a).order("status_id, s2b_position DESC")
    # Filter my issues 
    if session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:my] || session[:param_select_issues] == SELECT_ISSUE_OPTIONS[:my_completed]
      issues = issues.where(:assigned_to_id => User.current.id)
    end

    if session[:param_select_version] && session[:param_select_version] == "all"
      versions = Version.where(:project_id => @hierarchy_project_id).order("created_on")
    elsif session[:param_select_version] && session[:param_select_version] != "version_working" && session[:param_select_version] != "all"
      versions = Version.where(:id => session[:param_select_version]).order("created_on")
    else
      versions = Version.where(:project_id => @hierarchy_project_id).where("status NOT IN (?)","closed").order("created_on")
    end
    versions.each do |version|
      @sort_versions[version] = issues.where(:fixed_version_id => version)
    end
    
    id_issues = issues.collect{|id_issue| id_issue.id}
    @issues_backlog = Issue.where(:fixed_version_id => nil).where("id IN (?) AND project_id IN (?)", id_issues,@hierarchy_project_id).order("status_id, s2b_position")
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_lists/screen_list", :locals => {:sort_versions => @sort_versions, :issues_backlog => @issues_backlog})
      }
      format.html {}
    end
  end
  
  def change_sprint
    array_id= Array.new
    array_id = params[:issue_id]
    int_array = array_id.split(',').collect(&:to_i)

    issues = Issue.where("id IN (?) AND project_id IN (?)",int_array,@hierarchy_project_id)
    issues.each do |issue|
      issue.update_attribute(:fixed_version_id, params[:new_sprint])
    end
    filter_issues
  end
  
  def close_on_list
    array_id= Array.new
    array_id = params[:issue_id]
    int_array = array_id.split(',').collect(&:to_i)

    issues = Issue.where("id IN (?) AND project_id IN (?)",int_array,@hierarchy_project_id)
    issues.each do |issue|
      issue.update_attribute(:status_id, DEFAULT_STATUS_IDS['status_closed'])
    end
    filter_issues   
  end

end
