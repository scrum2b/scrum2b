class S2bIssuesController < S2bApplicationController
  
  before_filter :find_project, :only => [:show, :edit, :update, :create_comment]
                          
  def show
    return unless find_issue_from_param
    member = @project.assignable_users
    @id_member = member.collect{|id_member| id_member.id}
    @comments = Comment.where(:commented_type => "Issue",:commented_id => @issue.id)
    Rails.logger.info "AAAAAAAAAAAAAAAA #{@comments}"
    
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_issues/detail_issue", :locals => {:issue => @issue, :project => @project, :id_member => @id_member, :notes => @notes})
      }
    end
  end
  
  def edit
    return unless find_issue_from_param
    
  end
  
  def update
    return unless find_issue_from_param 
    member = @project.assignable_users
    @id_member = member.collect{|id_member| id_member.id} 
    
    
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    
    if @issue.update_attributes(params[:issue])
      respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_issues/detail_issue", :locals => {:issue => @issue, :project => @project, :id_member => @id_member})
      }
      end
    else
      render :json => {:result => "error", :message => @issue.errors.full_messages}
    end
    
  end
 
  protected
  
    def find_issue_from_param
      issue_id = params[:issue_id] || params[:id] || params[:issue][:id]
      @issue = @project.issues.find(issue_id)
      return true if @issue
    
      render :json => {:result => "error", :message => "Unknow issue"}
      return false
    end

end
