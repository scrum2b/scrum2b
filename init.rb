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
  project_module :scrum2b do
   permission :view_issue, :issue => :index
  end
  settings :default => {'status_no_start'=> [], 'status_inprogress' => [], 'status_completed' => [], 'status_closed' => [] }, :partial => 'settings/scrum2b'
 menu :project_menu, :scrum2b, { :controller => 'issue', :action => 'index' }, :caption => 'Scrum2B', :after => :activity, :param => :project_id
  
end
