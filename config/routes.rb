# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
#resources :issue

match 'scrum2b/list' => 'scrum2b_issues#index'
match 'scrum2b/board' => 'scrum2b_issues#board'
match "scrum2b/ajax" => "scrum2b_issues#ajax"
match 'scrum2b/update_status' => 'scrum2b_issues#update_status'
match "scrum2b/ajax" => "scrum2b_issues#ajax"
match "scrum2b/close_issue" => "scrum2b_issues#close_issue"
match "scrum2b/edit_issue" => "scrum2b_issues#edit_issue"
match "scrum2b/sort_issues" => "scrum2b_issues#sort_issues"
