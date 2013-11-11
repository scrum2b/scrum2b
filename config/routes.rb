# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'boards/index' => 's2b_boards#index'
match 'boards/update_status' => 's2b_boards#update_status'
match "boards/update_progress" => "s2b_boards#update_progress"
match "boards/close_issue" => "s2b_boards#close_issue"
match "boards/filter_issues_onboard" => "s2b_boards#filter_issues_onboard"
match "boards/update" => "s2b_boards#update"
match "boards/sort" => "s2b_boards#sort"
match "boards/new" => "s2b_boards#new"
match "boards/create" => "s2b_boards#create"

match 'lists/index' => 's2b_lists#index'
match "lists/filter_issues_onlist" => "s2b_lists#filter_issues_onlist"
match "lists/close_on_list" => "s2b_lists#close_on_list"
match "lists/change_sprint" => "s2b_lists#change_sprint"
