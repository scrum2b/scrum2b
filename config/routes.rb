# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#resources :issue
match '/issue/list' => 'issue#index'
match '/issue/board' => 'issue#board'
match "/issue/ajax" => "issue#ajax"
match '/issue/update_status' => 'issue#update_status'
match "/issue/ajax" => "issue#ajax"
match "/issue/close_issue" => "issue#close_issue"
match "/issue/sort_issues" => "issue#sort"





