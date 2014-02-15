require_dependency 'issue'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Deliverable
module IssuePatch
 def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      after_save :save_to_logs
      has_many :s2b_logs_version, :as => :s2b_logs_version
    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    # This will update all NextIssues assigned to the Issue
    #
    # * When an issue is closed, NextIssue#remove_associations_to will be called to
    #   update the set of NextIssues
    # * When an issue is reassigned, any previous (stale) NextIssues will
    #   be removed
    def save_to_logs
      self.reload
      issue_number = []
      total_process = 0
      Issue.where(:project_id => self.project_id).each_with_index do |issue, index|
        total_process += issue.done_ratio 
        issue_number << index
      end
        Rails.logger.info "total #{total_process}"
        max_index = issue_number.last + 1
        total_done_ratio = total_process/max_index
      #save to log version table
        unless S2bLogsVersion.existed.present?
          S2bLogsVersion.create(:done_ratio => total_done_ratio, :sprint => self.project_id,:working_days =>Time.now.utc.strftime("%Y,%m,%d")  )  
        else
          S2bLogsVersion.existed.first.update_attributes(:done_ratio => total_done_ratio, :sprint => self.project_id,:working_days => Time.now.utc.strftime("%Y,%m,%d"))
        end
        
    end
    
    def total_percent 
      return save_to_logs 
    end
    
  end      
end
