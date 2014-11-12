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
      render :json => {result: "error", message: @attachment.errors.full_messages}
    end
  end
  
  def upload_file
    if @attachment.save_attachments(params[:file])
      render :json => {:result => "success"}
    end
  end

end