require 'redmine'
#require 'application_helper_patch'

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
    permission :s2b_view_issue, {:s2b_lists => [:index, :filter_issues],:s2b_boards => [:index, :filter_issues]}
    permission :s2b_edit_issue, {:s2b_lists => [:index, :filter_issues, :close_on_list , :change_sprint],
                                 :s2b_boards => [:index, :filter_issues,:create, :update, :close_issue ,:sort, :update_progress, :update_status],
                                 :s2b_notes => [:create, :update, :delete]}           
  end
  menu :project_menu, :s2b_lists, { :controller => :s2b_lists, :action => :index }, :caption => :label_scrum2b, :after => :activity, :param => :project_id
end
