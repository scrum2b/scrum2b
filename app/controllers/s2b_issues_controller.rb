class S2bIssuesController < S2bApplicationController

  before_filter :get_members, :only => [:index, :get_data, :load_data]
  before_filter :find_issue, :only => [:destroy, :update, :update_status, :update_version, :update_progress, :get_files, :upload_file, :get_comments]
  before_filter lambda { check_permission(:edit) }, :only => [:index, :update]
  before_filter lambda { check_permission(:view) }, :only => [:index]
  
  def index

  end
  
  def get_data
    load_data
    @issues = opened_versions_list.first.fixed_issues
    @issues_backlog = Issue.where(:fixed_version_id => nil).where("project_id IN (?)",@hierarchy_project_id)
    render :json => {:versions => @versions, :issues => @issues, :issues_backlog => @issues_backlog, :tracker => @tracker, :priority => @priority, :status => @status, :members => @members, :status_ids => DEFAULT_STATUS_IDS}
  end
  
  def get_issues_version
    logger.info "Params version id  #{params[:version_id]}"
    version = Version.find(params[:version_id])
    @issues = version.fixed_issues # <- not too useful
    render :json => {:issues => @issues}
  end

  def get_issues_backlog
    @issues = version.fixed_issues # <- not too useful
    render :json => {:issues => @issues}
  end
  
  def create
    issue = Issue.new(params[:issue])
    if issue.save
      render :json => {:result => "create_success", :issue => issue}
    else
      render :json => {:result => issue.errors.full_messages}
    end
  end

  def destroy
    return unless @issue
    if @issue.destroy
      render :json => {:result => "success"}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def update
    if @issue.update_issue(params[:issue])
      render :json => {:result => "edit_success",:issue => @issue}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def update_status
    return unless @issue 
    if @issue.update_attributes(:status_id => params[:status_id], :fixed_version_id => params[:fixed_version_id])
      
      if STATUS_IDS['status_completed'].include?( params[:status_id].to_i) || STATUS_IDS['status_closed'].include?( params[:status_id].to_i)
        @issue.update_attributes(:done_ratio => 100)
        render :json => {:result => "update_success_completed",:issue => @issue}
      else
        render :json => {:result => "update_success",:issue => @issue}
      end
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def update_version
    return unless @issue
    if @issue.update_attributes(:fixed_version_id => params[:fixed_version_id])
      render :json => {:result => "update_success",:issue => @issue}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end
  
  def update_progress
    return unless @issue
    if @issue.update_attributes(:done_ratio => params[:done_ratio])
      render :json => {:result => "update_success",:issue => @issue}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def load_data
    @versions =  opened_versions_list
    @priority = IssuePriority.all
    @tracker = Tracker.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
  end
  
  def get_files
    return unless @issue
    @attachments = @issue.attachments
    logger.info "Array file #{@attachments}"
    render :json => {:attachments => @attachments}
  end
  
  def delete_file
    attachment = Attachment.find(params[:file_id])
    if attachment.destroy
      render :json => {:result => "success"}
    else
      render :json => {:result => attachment.errors.full_messages}
    end
  end
  
  def upload_file
    return unless @issue
    if @issue.save_attachments(params[:file])
      render :json => {:result => "success"}
    end
  end
  
  def get_comments
    return unless @issue
    @journals = @issue.journals.where(:journalized_type => "Issue")
    render :json => {:journals => @journals}
  end
  
  def delete_comment
    comment = Journal.find(params[:id])
    if comment.destroy
      render :json => {:result => "success"}
    else
      render :json => {:result => comment.errors.full_messages}
    end
  end
  
  def edit_comment
    @comment = Journal.find(params[:id])
    if @comment.update_attributes(:notes => params[:notes])
      render :json => {:result => "update_success",:comment => @comment}
    else
      render :json => {:result => @comment.errors.full_messages}
    end
  end

  def create_comment
    render :json => {:result => "update_success"}
  end

  def find_issue
    issue_id = params[:issue_id] || params[:id] || (params[:issue] && params[:issue][:id]) || (params[:issue] && params[:issue][:issue_id])
    @issue = Issue.find(issue_id) rescue nil
  end

end
