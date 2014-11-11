class S2bCommentsController < S2bApplicationController

  before_filter :set_issue, :only => [:index, :destroy, :edit, :create]
  before_filter :set_comment, :only => [:destroy, :edit, :update]

  before_filter lambda { validate_permission_for?(:edit) }, :only => [:edit, :update, :new, :create, :destroy]
  before_filter lambda { validate_permission_for?(:view) }, :only => [:index]
    
  def index
    return unless @issue
    @comments = @issue.journals.where(:journalized_type => "Issue")
    render :json => {comments: @comments}
  end
  
  def destroy
    if @comment.present? && @comment.destroy
      render :json => {result: "success"}
    else
      render :json => {result: "error", message: comment.errors.full_messages}
    end
  end
  
  def edit
    if @comment.update_attributes(:notes => params[:notes])
      render :json => {result: "update_success", comment: @comment}
    else
      render :json => {result: "error", message: @comment.errors.full_messages}
    end
  end

  def create
    #TODO: need to implement this action
    render :json => {result: "draft_action"}
  end

  private

    def set_issue
      issue_id = params[:issue_id] || params[:id] || (params[:issue] && params[:issue][:id]) || (params[:issue] && params[:issue][:issue_id])
      #TODO: check permission for this issue's instance with @hierarchy_projects
      @issue = Issue.find(issue_id) rescue nil
    end
    
    def set_comment
      #TODO: check permission for this comment's instance with @hierarchy_projects
      @comment = Journal.find(params[:id])
    end

end