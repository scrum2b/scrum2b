class S2bCommentController < CommentsController
  before_filter :find_project
  before_filter :find_issue
  
  def create
    member = @project.assignable_users
    @id_member = member.collect{|id_member| id_member.id}
    comment = Comment.new(params[:comment])
    if comment.save
      @comments = Comment.where(:commented_type => "Issue",:commented_id => @issue.id)
      respond_to do |format|
        format.js {
          @return_content = render_to_string(:partial => "/s2b_issues/detail_issue", :locals => {:issue => @issue, :project => @project, :id_member => @id_member, :notes => @notes})
        }
      end
    else
      render :json => {:result => "error", :message => comment.errors.full_messages}
    end
  end
  
  def delete
    comment = Comment.find(params[:comment_id]).destroy
    respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_issues/detail_issue", :locals => {:issue => @issue, :project => @project, :id_member => @id_member, :notes => @notes})
      }
    end
  end
  
  private
  
  def find_issue
    issue_id = params[:issue_id] || params[:id] || params[:comment][:commented_id]
    @issue = Issue.find(issue_id)
   end
   
   def find_project
    # @project variable must be set before calling the authorize filter
    project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
    @project = Project.find(project_id)
  end
  
end