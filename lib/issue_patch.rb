require_dependency 'issue'
module IssuePatch
  def self.included(base)
    base.send(:include, S2bIssue)
  end

  
  module S2bIssue
    def update_issue(params_issue)
      return true if self.update_attributes(:subject => params_issue[:subject],
                                            :description => params_issue[:description], 
                                            :estimated_hours => params_issue[:estimated_hours],
                                            :priority_id => params_issue[:priority_id], 
                                            :assigned_to_id => params_issue[:assigned_to_id],
                                            :start_date => params_issue[:start_date], 
                                            :due_date => params_issue[:due_date],
                                            :tracker_id => params_issue[:tracker_id])
    end
  end    
end