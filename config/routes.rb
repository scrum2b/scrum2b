# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :issue
match '/issue/list' => 'issue#list'
