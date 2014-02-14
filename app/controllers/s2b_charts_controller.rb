class S2bChartsController < S2bApplicationController

  unloadable
  helper :sort
  include SortHelper
  helper :issues
  include ApplicationHelper
  helper :timelog
  
  WORKING_DAYS = Time.now
  
  skip_before_filter :verify_authenticity_token
  before_filter :find_project
  before_filter :get_members, :only => :index
  before_filter lambda { check_permission(:view) }, :only => :index
  before_filter :find_version, :only => [:index, :find_issues]
  
  def index
    # Start and End date
    start_date = @project.versions.minimum(:created_on).to_date
    end_date = @project.versions(:effective_date)? @project.versions.maximum(:effective_date).to_date : WORKING_DAYS
    @start_date = start_date
    # Count number of day for work
    @working_days = (start_date..end_date).inject([]) { |x, date| x << date.strftime("%Y-%m-%d")}
    #Calculate hours
    @not_complete = [100]
    total_hours = 0
    done_ratio = 0
    find_issues.each do |issue|
      total_hours += issue.estimated_hours if issue.estimated_hours
      done_ratio += issue.done_ratio 
    end
    data = []
    chart_index = ["",""]
    S2bLogsVersion.all.each do |f| 
      chart_index = "[Date.UTC(#{f.working_days}), #{100 - f.done_ratio.to_i}]"
      data << chart_index
    end
    Rails.logger.info "TEST #{data}"
    @not_complete = "[#{data.join(",\n")}]"
  end
  
  
  def find_issues
    all_versions = @project.versions.select(&:effective_date).sort_by(&:effective_date) 
    all_issues = Issue.find(:all) 
    #all_versions.each do |version|
    #TODO Optimize later if chart for each sprint
      # issues = Issue.find_by_sql([
          # "select * from issues
             # where fixed_version_id = :version_id and start_date is not NULL and
               # estimated_hours is not NULL order by start_date asc",
                 # {:version_id => version.id}])
    return all_issues
  end
  
  protected
  
  def find_version
    @list_versions_open = opened_versions_list
    @list_versions_closed = closed_versions_list
    all_versions = @project.versions.select(&:effective_date).sort_by(&:effective_date) 
  end
  
  
end