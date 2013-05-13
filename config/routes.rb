# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'scrum2b/list' => 'scrum2b_issues#index'
match 'scrum2b/board' => 'scrum2b_issues#board'
match 'scrum2b/update_status' => 'scrum2b_issues#update_status'
match "scrum2b/update_progress" => "scrum2b_issues#update_progress"
match "scrum2b/close" => "scrum2b_issues#close"
match "scrum2b/update" => "scrum2b_issues#update"

match "scrum2b/sort" => "scrum2b_issues#sort"
match "scrum2b/new" => "scrum2b_issues#new"
match "scrum2b/create" => "scrum2b_issues#create"
match "scrum2b/change_sprint" => "scrum2b_issues#change_sprint"
