class AddColumnIssuePosition < ActiveRecord::Migration
  def up
  	add_column :issues, :position,:string
  end

  def down
  	remove_column :issues, :position,:string
  end
end
