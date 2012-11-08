# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#resources :issue
match '/issue/list' => 'issue#index'
match '/issue/board' => 'issue#board'
match "/issue/ajax" => "issue#ajax"




