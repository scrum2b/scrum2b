class S2bIssuesController < S2bApplicationController

  #before_filter :check_before, :only => [:index]
  before_filter :get_members, :only => [:index, :get_data, :load_data]
  before_filter lambda { check_permission(:edit) }, :only => [:index, :update]
  before_filter lambda { check_permission(:view) }, :only => [:index]
  
  def index
    # issues = Issue.all
    # issues.each do |is|
      # is.destroy
    # end
    # issues = Issue.last
    # issues.update_attributes(:status_id => 3)
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
    logger.info ""
    @issues = version.fixed_issues # <- not too useful
    render :json => {:issues => @issues}
  end
  
  def create
    #Creat new issue
    logger.info "params issue #{params[:issue]}"
    @issue = Issue.new(params[:issue])
    if @issue.save
      render :json => {:result => "create_success", :issue => @issue}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def destroy
    @issue = Issue.find(params[:id])
    if @issue.destroy
      render :json => {:result => "success"}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def update
    logger.info "Prams Issue #{params[:issue]}"
    @issue = Issue.find(params[:issue][:id])
    if @issue.update_attributes(:subject => params[:issue][:subject], :description => params[:issue][:description], :estimated_hours => params[:issue][:estimated_hours],
                                :priority_id => params[:issue][:priority_id], :assigned_to_id => params[:issue][:assigned_to_id],
                                :start_date => params[:issue][:start_date], :due_date => params[:issue][:due_date],:tracker_id => params[:issue][:tracker_id])
      render :json => {:result => "edit_success",:issue => @issue}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def update_status
    logger.info "update status #{params}"
    @issue = Issue.find(params[:id])
    if @issue.update_attributes(:status_id => params[:status_id], :fixed_version_id => params[:fixed_version_id])
      render :json => {:result => "update_success",:issue => @issue}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end

  def update_version
    logger.info "update version #{params}"
    @issue = Issue.find(params[:id])
    if @issue.update_attributes(:fixed_version_id => params[:fixed_version_id])
      render :json => {:result => "update_success",:issue => @issue}
    else
      render :json => {:result => @issue.errors.full_messages}
    end
  end
  
  def update_progress
    logger.info "update version #{params}"
    @issue = Issue.find(params[:id])
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
    @issue = Issue.find(params[:issue_id])
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
    issue = Issue.find(params[:id])
    if issue.save_attachments(params[:file])
      render :json => {:result => "success"}
    end
  end
  
  def get_comments
    issue = Issue.find(params[:issue_id])
    @journals = issue.journals.where(:journalized_type => "Issue")
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
end
