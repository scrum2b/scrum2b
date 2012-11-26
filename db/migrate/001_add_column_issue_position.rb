class AddColumnIssuePosition < ActiveRecord::Migration
  def up
  	add_column :issues, :position, :integer
  end

  def down
  	remove_column :issues, :position, :integer
  end
end
