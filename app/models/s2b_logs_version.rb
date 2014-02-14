class S2bLogsVersion < ActiveRecord::Base
  unloadable
  scope :existed, -> { where("working_days=?",Time.now.utc.strftime("%Y,%m,%d"))}
end
