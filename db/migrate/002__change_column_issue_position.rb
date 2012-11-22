class ChangeColumnIssuePosition < ActiveRecord::Migration
  def up
  	remove_column :issues,:position
  	add_column :issues,:position,:integer
  end

  def down
  	
  end
end
