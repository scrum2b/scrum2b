class AddColumnIssuePosition < ActiveRecord::Migration
  def up
    add_column :issues, :s2b_position, :integer
  end

  def down
  	remove_column :issues, :s2b_position, :integer
  end
end
