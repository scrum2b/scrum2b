# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
  resources :issue
  get 'scrum2be', :to => 'issue#index'