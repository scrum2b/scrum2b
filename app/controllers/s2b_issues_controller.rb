class S2bIssuesController < S2bApplicationController
  
  skip_before_filter :verify_authenticity_token
  before_filter :find_project
  before_filter :find_issue_from_param
  before_filter :check_before
  before_filter lambda { check_permission(:edit) }, :only => [:update, :delete_attach, :delete]

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include Redmine::Export::PDF
  helper :issues
  include IssuesHelper

  def show
    return unless find_issue_from_param
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_issues/detail_issue", :locals => {:issue => @issue, :project => @project, :journals => @journals})
      }
    end
  end
  
  def edit
    return unless find_issue_from_param
  end
  
  def update
    return unless find_issue_from_param 
    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    
    if @issue.update_attributes(params[:issue])
      redirect_to :controller => "s2b_boards",:action => "index", :project_id => @project.id
      flash[:notice] = "Successfully update issue #{@issue.id}"
      flash[:show_detail] = "#{@issue.id}"
    else
      redirect_to :controller => "s2b_boards",:action => "index", :project_id => @project.id
      flash[:error] = "Error update issue #{@issue.id}"
      flash[:show_detail] = "#{@issue.id}"
    end
    
  end
  
  def delete_attach
    return unless params[:attach_id]
    @attachment = Attachment.find(params[:attach_id])
      if @attachment.destroy()
       respond_to do |format|
        format.js {
          @return_content = render_to_string(:partial => "/s2b_issues/detail_issue", :locals => {:issue => @issue, :project => @project})
        }
      end
    else
      render :json => {:result => "error"}
    end
    
  end

  def delete
    @issue = Issue.find(params[:issue_id])
    unless @issue
      render :json => {:result => "error", :message => "Unknow issue"}
      return 
    end
    if @issue.destroy()
      render :json => {:result => "success"}
    else
      render :json => {:result => "error"}
    end
  end
  
  protected
  
  def find_issue_from_param
    issue_id = params[:issue_id] || params[:id] || params[:issue][:id]
    @issue = Issue.find(issue_id)
    return true if @issue
  
    render :json => {:result => "error", :message => "Unknow issue"}
    return false
  end
  
  def check_before
    @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals.reverse! if User.current.wants_comments_in_reverse_order? 
    
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
  end
end
