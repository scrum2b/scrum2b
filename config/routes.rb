# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get  's2b_issues/get_data' => 's2b_issues#get_data'
post 's2b_issues/get_data' => 's2b_issues#get_data'
get  's2b_issues/destroy' => 's2b_issues#destroy'
post 's2b_issues/destroy' => 's2b_issues#destroy'
get  's2b_issues/update' => 's2b_issues#update'
post 's2b_issues/update' => 's2b_issues#update'
get  's2b_issues/update_status' => 's2b_issues#update_status'
post 's2b_issues/update_status' => 's2b_issues#update_status'
get  's2b_issues/update_version' => 's2b_issues#update_version'
post 's2b_issues/update_version' => 's2b_issues#update_version'

post 's2b_issues/get_files' => 's2b_issues#get_files'
post 's2b_issues/delete_file' => 's2b_issues#delete_file'
post 's2b_issues/upload_file' => 's2b_issues#upload_file'

post 's2b_issues/get_comments' => 's2b_issues#get_comments'
post 's2b_issues/delete_comment' => 's2b_issues#delete_comment'
post 's2b_issues/edit_comment' => 's2b_issues#edit_comment'
post 's2b_issues/create_comment' => 's2b_issues#create_comment'

get  's2b_issues/update_progress' => 's2b_issues#update_progress'
post 's2b_issues/update_progress' => 's2b_issues#update_progress'

post 's2b_issues/get_issues_version' => 's2b_issues#get_issues_version'
get  's2b_issues/get_issues_version' => 's2b_issues#get_issues_version'
post 's2b_issues/create' => 's2b_issues#create'

post 's2b_issues/index' => 's2b_issues#index'
get  's2b_issues/index' => 's2b_issues#index'
# post 's2b_boards/update_status' => 's2b_boards#update_status'
# post "s2b_boards/update_progress" => "s2b_boards#update_progress"
# post "s2b_boards/close_issue" => "s2b_boards#close_issue"
# post "s2b_boards/filter_issues" => "s2b_boards#filter_issues"
# post "s2b_boards/update" => "s2b_boards#update"
# post "s2b_boards/sort" => "s2b_boards#sort"
# get  "s2b_boards/new" => "s2b_boards#new"
# post "s2b_boards/create" => "s2b_boards#create"
# post "s2b_boards/draw_issue" => "s2b_boards#draw_issue"
# 
# post 's2b_lists/index' => 's2b_lists#index'
# get  's2b_lists/index' => 's2b_lists#index'
# post "s2b_lists/filter_issues" => "s2b_lists#filter_issues"
# post "s2b_lists/close_on_list" => "s2b_lists#close_on_list"
# post "s2b_lists/change_sprint" => "s2b_lists#change_sprint"
# 
# 
# post "s2b_issues/show" => "s2b_issues#show"
# get  "s2b_issues/edit" => "s2b_issues#edit"
# put  "s2b_issues/update" => "s2b_issues#update"
# post "s2b_issues/delete" => "s2b_issues#delete"
# 
# post "s2b_issues/delete_attach" => "s2b_issues#delete_attach"
# 
# post "s2b_notes/update" => "s2b_notes#update"
# post "s2b_notes/delete" => "s2b_notes#delete"
# post "s2b_notes/create" => "s2b_notes#create"

