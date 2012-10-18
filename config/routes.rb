# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :issue
match "issues/lists" => "issue#index"

 
  