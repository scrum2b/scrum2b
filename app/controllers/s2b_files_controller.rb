class S2bFilesController < S2bApplicationController

  before_filter :set_issue, :only => [:index, :destroy, :edit, :create]
  before_filter :set_attachment, :only => [:destroy, :edit, :update]

  before_filter lambda { validate_permission_for?(:edit) }, :only => [:edit, :update, :new, :create, :destroy]
  before_filter lambda { validate_permission_for?(:view) }, :only => [:index]
    
  def index
    return unless @issue
    @attachments = @issue.attachments
    render :json => {:attachments => @attachments}
  end
  
  def destroy
    if @attachment.present? && @attachment.destroy
      render :json => {:result => "success"}
    else
      render :json => {result: "error", message: comment.errors.full_messages}
    end
  end
  
  def upload_file
    if @attachment.save_attachments(params[:file])
      render :json => {:result => "success"}
    end
  end

  private

    def set_issue
      issue_id = params[:issue_id] || params[:id] || (params[:issue] && params[:issue][:id]) || (params[:issue] && params[:issue][:issue_id])
      #TODO: check permission for this issue's instance with @hierarchy_projects
      @issue = Issue.find(issue_id) rescue nil
    end

    def set_attachment
      #TODO: check permission for this comment's instance with @hierarchy_projects
      @attachment = Attachment.find(params[:file_id])
    end

end