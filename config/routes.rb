# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 's2b_boards/index' => 's2b_boards#index'
get  's2b_boards/index' => 's2b_boards#index'
post 's2b_boards/update_status' => 's2b_boards#update_status'
post "s2b_boards/update_progress" => "s2b_boards#update_progress"
post "s2b_boards/close_issue" => "s2b_boards#close_issue"
post "s2b_boards/filter_issues" => "s2b_boards#filter_issues"
post "s2b_boards/update" => "s2b_boards#update"
post "s2b_boards/sort" => "s2b_boards#sort"
get  "s2b_boards/new" => "s2b_boards#new"
post "s2b_boards/create" => "s2b_boards#create"
post "s2b_boards/draw_issue" => "s2b_boards#draw_issue"

post 's2b_lists/index' => 's2b_lists#index'
get  's2b_lists/index' => 's2b_lists#index'
post "s2b_lists/filter_issues" => "s2b_lists#filter_issues"
post "s2b_lists/close_on_list" => "s2b_lists#close_on_list"
post "s2b_lists/change_sprint" => "s2b_lists#change_sprint"


post "s2b_issues/show" => "s2b_issues#show"
get  "s2b_issues/edit" => "s2b_issues#edit"
put  "s2b_issues/update" => "s2b_issues#update"
post "s2b_issues/delete" => "s2b_issues#delete"

post "s2b_issues/delete_attach" => "s2b_issues#delete_attach"

post "s2b_notes/update" => "s2b_notes#update"
post "s2b_notes/delete" => "s2b_notes#delete"
post "s2b_notes/create" => "s2b_notes#create"

