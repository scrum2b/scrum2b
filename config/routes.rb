# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'boards/index' => 's2b_boards#index'
match 'boards/update_status' => 's2b_boards#update_status'
match "boards/update_progress" => "s2b_boards#update_progress"
match "boards/close_issue" => "s2b_boards#close_issue"
match "boards/filter_issues" => "s2b_boards#filter_issues"
match "boards/update" => "s2b_boards#update"
match "boards/sort" => "s2b_boards#sort"
match "boards/new" => "s2b_boards#new"
match "boards/create" => "s2b_boards#create"
match "boards/delete" => "s2b_boards#delete"

match 'lists/index' => 's2b_lists#index'
match "lists/filter_issues" => "s2b_lists#filter_issues"
match "lists/close_on_list" => "s2b_lists#close_on_list"
match "lists/change_sprint" => "s2b_lists#change_sprint"


match "s2b_issues/show" => "s2b_issues#show"
match "s2b_issues/edit" => "s2b_issues#edit"
match "s2b_issues/update" => "s2b_issues#update"
match "s2b_issues/delete" => "s2b_issues#delete"

match "s2b_notes/update" => "s2b_notes#update"
match "s2b_notes/delete" => "s2b_notes#delete"
match "s2b_notes/create" => "s2b_notes#create"

match "s2b_attachments/upload" => "s2b_attachments#upload"
match "s2b_attachments/delete" => "s2b_attachments#delete"

