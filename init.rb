require 'redmine'
#require 'application_helper_patch'

#Rails.configuration.to_prepare do
#  ApplicationHelper.send(:include, PluginName::Patches::ApplicationtHelperPatch) unless ApplicationHelper.included_modules.include? PluginName::Patches::ApplicationtHelperPatch
#end

Redmine::Plugin.register :scrum2b do
  name 'Scrum2B Plugin'
  author 'Scrum2B'
  description %Q{A scrum tool for team to work:
                  - Scrum board
                  - Customize views
                }
  version '0.1'
  url 'https://github.com/scrum2b/scrum2b'
  author_url 'http://scrum2b.com'

  settings :default => {'status_no_start'=> {}, 'status_inprogress' => {}, 'status_completed' => {}, 'status_closed' => {} }, :partial => 'settings/scrum2b'
  
  project_module :scrum2b do
    permission :view_issue, :s2b_lists => :index
    permission :view_issue, :s2b_boards => :index
  end
  menu :project_menu, :s2b_lists, { :controller => :s2b_lists, :action => :index }, :caption => :label_scrum2b, :after => :activity, :param => :project_id
end