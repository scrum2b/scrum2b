class S2bIssuesController < S2bApplicationController
  
  before_filter :find_project, :only => [:show, :edit, :update]
                          
  def show
    return unless find_issue_from_param
    @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
     
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id} 
    
    
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_issues/detail_issue", :locals => {:issue => @issue, :project => @project, :id_member => @id_member})
      }
    end
  end
  
  def edit
    return unless find_issue_from_param
    
  end
  
  def update
    return unless find_issue_from_param 
    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
     
    @member = @project.assignable_users
    @id_member = @member.collect{|id_member| id_member.id} 
    
    
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
