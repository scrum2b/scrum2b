class S2bNotesController < S2bApplicationController
  
  skip_before_filter :verify_authenticity_token
  before_filter :find_project
  before_filter :find_issue
  before_filter lambda { check_permission(:edit) }, :only => [:update, :create, :delete]
  
  def create
    @journal = Journal.new(params[:journal])
    if @journal.save
      @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
      respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_notes/show", :locals => {:journals => @journals, :issue => @issue , :project => @project})
      }
      end
    else
      render :json => {:result => "error", :message => @journal.errors.full_messages}
    end
  end
  
  def update
    @journal = Journal.find(params[:journal][:id])
    @journal.notes = params[:journal][:notes]
    if @journal.save
      @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
      respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_notes/show", :locals => {:journals => @journals, :issue => @issue , :project => @project})
      }
      end
    else
      render :json => {:result => "error", :message => @journal.errors.full_messages}
    end
  end
  
  def delete
    @journal = Journal.find(params[:notes_id])
    if @journal.destroy
      @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
      respond_to do |format|
      format.js {
        @return_content = render_to_string(:partial => "/s2b_notes/show", :locals => {:journals => @journals, :issue => @issue , :project => @project})
      }
      end
    else
      render :json => {:result => "error", :message => @journal.errors.full_messages}
    end
  end
  
  private

  def find_issue
    issue_id = params[:issue_id] || params[:id]
    @issue = Issue.find(issue_id)
  end

end