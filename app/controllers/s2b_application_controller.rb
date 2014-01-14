class S2bApplicationController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token
  before_filter :set_status_settings
  before_filter :find_project
  
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include Redmine::Export::PDF
  helper :issues
  include IssuesHelper
  helper_method :editable_for_project?
  helper_method :viewable_for_project?
  self.allow_forgery_protection = false
  
  DEFAULT_STATUS_IDS = {}
  STATUS_IDS = {'status_no_start' => [], 'status_inprogress' => [], 
                'status_completed' => [], 'status_closed' => []}
                
  SELECT_ISSUE_OPTIONS = {:all_working => 1,
                          :my => 2, 
                          :my_completed => 3, 
                          :new => 4, 
                          :completed => 5,
                          :closed => 6,
                          :all => 7}
  
  def editable_for_project?
    return @editable_for_project if @editable_for_project.present?
    @viewable_for_project = true and return true if User.current.admin?

    @user_roles = @user_roles || User.current.roles_for_project(@project)
    @editable_for_project = false
    @user_roles.each do |role|
      @editable_for_project = true and break if role.permissions.include?(:s2b_edit_issue)
    end
    return @editable_for_project  
  end
  
  def viewable_for_project?
    return @viewable_for_project if @viewable_for_project.present? 
    @viewable_for_project = true and return true if User.current.admin?
    
    @user_roles = @user_roles || User.current.roles_for_project(@project)
    @viewable_for_project = false
    @user_roles.each do |role|
      @viewable_for_project = true and break if role.permissions.include?(:s2b_view_issue)
    end
    return @viewable_for_project
  end

  def check_permission(permission_type = :view)
    redirect_to :back if permission_type == :view && !viewable_for_project?
    redirect_to :back if permission_type == :edit && !editable_for_project?
  end
      
  protected
  
  def opened_versions_list
    find_project unless @project
    return @project.versions.where(:status => "open")
  end
  
  def closed_versions_list 
    find_project unless @project
    return @project.versions.where(:status => "closed")
  end
  
  def find_project
    # @project variable must be set before calling the authorize filter
    project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
    @project = Project.find(project_id)
    @hierarchy_project = Project.where(:parent_id => @project.id) << @project
    @hierarchy_project_id = @hierarchy_project.collect{|project| project.id}
  end
  
  def get_members
    @members = []
    @hierarchy_project.each do |project|
      project.assignable_users.each do |user|
        @members.push(user) unless @members.include?(user)
      end
    end
  end
  
  def set_status_settings
    @plugin = Redmine::Plugin.find("scrum2b")
    @settings = Setting["plugin_#{@plugin.id}"]   
    # Loop to set default of settings items
    need_to_resetting = false
    STATUS_IDS.keys.each do |column_name|
      @settings[column_name].keys.each { |setting| 
        STATUS_IDS[column_name].push(setting.to_i) 
      } if @settings[column_name]
      
      if STATUS_IDS[column_name].empty?
        need_to_resetting = true;
      else
        DEFAULT_STATUS_IDS[column_name] = STATUS_IDS[column_name].first.to_i
      end
    end
     
    if need_to_resetting
      flash[:notice] = "The system has not been setup to use Scrum2B Tool. Please contact to Administrator " + 
                       "or go to the Settings page of the plugin: <a href='/settings/plugin/scrum2b'>/settings/plugin/scrum2b</a> to config."
      redirect_to "/projects/#{@project.to_param}"
    end
  end
end
