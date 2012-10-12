Redmine::Plugin.register :scrum2be do
  name 'Scrum2be plugin'
  author 'Scrum2be'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  project_module :scrum2be do
   permission :view_issue, :issue => :index
  end
 menu :project_menu, :scrum2be, { :controller => 'issue', :action => 'index' }, :caption => 'S2be', :after => :activity, :param => :project_id
  
end
