class CreateS2bLogsVersions < ActiveRecord::Migration
  def change
    create_table :s2b_logs_versions do |t|
      t.column "start_date", :timestamp
      t.column "story_point", :float
      t.column "issue_id", :integer
      t.column "working_days", :string
      t.column "sprint", :string
      t.column "expecting_date", :timestamp
      t.column "done_ratio", :string
    end
  end
end
