require_dependency 'issue'

module IssuePatch
  def self.included(base)
    base.send(:include, S2bIssue)
  end

  module S2bIssue
    def update_issue(params, constant_status_ids = nil)
      return false if params.nil? || params.keys.empty?
      if !constant_status_ids.nil? && (constant_status_ids['status_completed'] + constant_status_ids['status_closed']).include?(params[:status_id].to_i)
        params.merge!(:done_ratio => 100)
      end
      return self.update_attributes(params)
    end

    def completed?(constant_status_ids)
      constant_status_ids && (constant_status_ids['status_completed'] + constant_status_ids['status_closed']).include?(self.status_id)
    end
  end    
end