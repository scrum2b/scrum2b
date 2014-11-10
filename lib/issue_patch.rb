require_dependency 'issue'
module IssuePatch
  def self.included(base)
    base.send(:include, S2bIssue)
  end

  
  module S2bIssue
    def completed_done_radio
      self.update_attributes(:done_ratio => 100)
    end

    def update_issue(params)
      return true if self.update_attributes(params)
    end
  end    
end