require 'redmine'
require 'gravatar'

require 'issue_patch'
Issue.send(:include, IssuePatch)


#Rails.configuration.to_prepare do
#  ApplicationHelper.send(:include, PluginName::Patches::ApplicationtHelperPatch) unless ApplicationHelper.included_modules.include? PluginName::Patches::ApplicationtHelperPatch
#end

Redmine::Plugin.register :scrum2b do
  name 'Scrum2B Plugin'
  author 'ScrumTobe Team'
  description %Q{A scrum tool for team to work:
                  - Scrum board
                  - Customize views
                }
  version '2.0'
  url 'https://github.com/scrum2b/scrum2b'
  author_url 'http://www.scrumtobe.com'

  settings :default => {'status_no_start'=> {}, 'status_inprogress' => {}, 'status_completed' => {}, 'status_closed' => {} }, :partial => 'settings/scrum2b'
  
  project_module :scrum2b do
    permission :s2b_view_issue, {:s2b_issues => [:index, :get_data, :load_data, :get_files, :get_comments] }
    permission :s2b_edit_issue, {:s2b_issues => [:index, :get_data, :load_data, :get_files, :get_comments,
                                                 :get_issues_version, :get_issues_backlog, 
                                                 :delete_file, :upload_file,
                                                 :delete_comment, :edit_comment, :create_comment,
                                                 :update_status, :update_version, :update_progress, 
                                                 :create, :destroy, :update] }   
  end
  menu :project_menu, :s2b_issues, { :controller => :s2b_issues, :action => :index }, :caption => :label_scrum2b, :after => :activity, :param => :project_id
end
