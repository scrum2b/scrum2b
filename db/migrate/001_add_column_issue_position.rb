class AddColumnIssuePosition < ActiveRecord::Migration[5.0]
  def change
    add_column :issues, :s2b_position, :integer
  end
end
