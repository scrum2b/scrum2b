class IssueController < ApplicationController
  unloadable
  before_filter :find_project, :only => [:index,:list]
  def index
    @list_versions = @project.versions.all
    @version = @project.versions.all
    @issues_backlog = @project.issues.where(:fixed_version_id => nil ).all

  end

  def list
    @list_versions = @project.versions.all
    @id_version  = params[:select_version]
    @select_issues  = params[:select_issue]

    if @select_issues
      if @select_issues == "1"
        @issues =  @project.issues.all
      end
      if @select_issues == "2"
        @issues =  @project.issues.where(:assigned_to_id => User.current.id)
      end
      if @select_issues == "3"
        @issues =  @project.issues.where(:assigned_to_id => User.current.id , :done_ratio => 100)
      end
      if @select_issues == "4"
        @issues =  @project.issues.order("created_on DESC").limit(20)
      end
      if @select_issues == "5"
        @issues =  @project.issues.where(:done_ratio => 100 ).all
      end
    elsif
    @issues = @project.issues.all
    end

    if @id_version
      if @id_version == "all"
        @version = @project.versions.all

      elsif
      @version = Version.where(:id => @id_version);
      end
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
