class IssueController < ApplicationController
  unloadable
  before_filter :find_project, :only => [:index,:board]
 #layout false
  def index
    if session[:view_mode]&& session[:view_mode] = "board" && !params[:view_mode]
      session[:view_mode] = "board"
    end
    if !session[:view_mode] && !params[:view_mode]
      session[:view_mode] = "list"
    end
    if !session[:view_mode] || params[:view_mode] && params[:view_mode] == "List"
    session[:view_mode] = "list"
    end
    @list_versions = @project.versions.all
    @id_version  = params[:select_version]
    @select_issues  = params[:select_issue]
    if @select_issues
      if @select_issues == "1"
        @issues =  @project.issues
      end
      if @select_issues == "2"
        @issues =  @project.issues.where(:assigned_to_id => User.current.id)
      end
      if @select_issues == "3"
        @issues =  @project.issues.where(:assigned_to_id => User.current.id , :done_ratio => 100)
      end
      if @select_issues == "4"
        @issues =  @project.issues.where(:assigned_to_id => nil)
      end
      if @select_issues == "5"
        @issues =  @project.issues.where(:done_ratio => 100 )
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
    @issues_backlog = @project.issues.where(:fixed_version_id => nil).all
  end

  def board
    session[:view_mode] = "board"
    @list_versions = @project.versions.all
    @member = @project.assignable_users
    @id_version  = params[:select_version]
    @select_issues  = params[:select_member]

    if @select_issues

      if @select_issues == "all"
        @issues =  @project.issues

      elsif @select_issues == "me"
        @issues =  @project.issues.where(:assigned_to_id => User.current.id )

      else
        @issues =  @project.issues.where(:assigned_to_id => @select_issues)
      end

    else
      @issues = @project.issues
    end

    if @id_version
      if @id_version == "all"
        @version = @project.versions
      elsif
      @version = Version.where(:id => @id_version);
      end
    elsif
    @version = @project.versions
    end
    @id_version = Array.new
    @version.each do |version|
      @id_version.push(version.id)
    end
    @issues_select = @issues.where(:fixed_version_id => @id_version)
    @issues_new = @project.issues.where(:assigned_to_id => nil)
    @issues_completed = @issues_select.where(:done_ratio => 100)
    @issues_started = @issues_select.where("done_ratio < 100 AND assigned_to_id != 0 ")
  end
  def ajax
   @project =  Project.find(params[:project_id])
   #@issue = @project.issues.where(:id => params[:issue_id])
    @issue = @project.issues.find(params[:issue_id])
    @issue.update_attribute(:done_ratio, params[:done_ratio])
    Rails.logger.info "test object: #{@issue.done_ratio.to_s}"
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
end
