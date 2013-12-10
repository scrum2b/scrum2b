class S2bIssuesController < ApplicationController
  
  before_filter :find_project, :only => [:show, :edit, :update]
                          
  def show
    return unless find_issue_from_param
    
  end
  
  def edit
    return unless find_issue_from_param
    
  end
  
  def update
    
    
  end
  
  protected
  
    def find_issue_from_param
      @issue = @project.issues.find(params[:issue_id])
      return true if @issue
    
      render :json => {:result => "error", :message => "Unknow issue"}
      return false
    end

end
