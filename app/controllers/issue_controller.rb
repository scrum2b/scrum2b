class IssueController < ApplicationController
  unloadable
  before_filter :find_project, :authorize, :only => :index
 
  def index
   @list_version = @project.versions.all
   @id_version  = nil
   if @id_version
     @version = Version.where(:id => @id_version);
     
   elsif
    @version = @project.versions.all
   end
   @issues_backlog = @project.issues.where(:fixed_version_id => nil ).all
  
  end


  
  private
  
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
end
