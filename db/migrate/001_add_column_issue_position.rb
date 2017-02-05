class AddColumnIssuePosition < ActiveRecord::Migration
  def change
    add_column :issues, :s2b_position, :integer
  end
end
