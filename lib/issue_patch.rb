require_dependency 'issue'
module IssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, S2bIssue)
    base.class_eval do
      unloadable
    end
  end

  module ClassMethods

  end
  
  module S2bIssue
    def update_status(status_id, version_id)
      Rails.logger.info "AAAAAAAAAAAAAAAA #{params}"
      return true if self.update_attributes(:status_id => status_id, :fixed_version_id => version_id)
    end
  end    
end
Issue.send(:include, IssuePatch)