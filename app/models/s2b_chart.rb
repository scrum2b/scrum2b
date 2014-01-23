class S2bChart
  attr_accessor :working_days, :version, :start_date, :issues, :expecting_time, :sprint
  
  def initialize(version, issues=nil)
    self.version = version
#    self.all_issues = (issues.nil? ? version.fixed_issues.find(:all, :include => [{:journals => :details}, :relations_from, :relations_to]) : issues )
    self.issues = version.fixed_issues.find(:all, :include => [{:journals => :details}, :relations_from, :relations_to], 
                                                   :conditions => (issues.nil? ? nil : ["id IN (#{issues.join(',')}) "]))
    self.start_date = version.created_on.to_date #version.created_on.to_date
    end_date = (version.effective_date.nil? or version.effective_date.to_date < start_date)? start_date + 1.month : version.effective_date.to_date
    self.working_days = (start_date..end_date).inject([]) { |x, date| x << date }
    self.expecting_time = expect_data
    self.sprint = sprint_data
  end
  
  def sprint_data
    @sprint_data = []
    working_dats.each do |date|
      total_remaining = 0
      entries_today_or_earlier = []
      all_issues.each do |issue|
        issue_today_or_earlier = (issue.created_on.to_date <= date)
        if issue_today_or_earlier
          entries_today_or_earlier << issue.remaining_effort_entries.select { |a| a.created_on.to_date <= date}.last
          total_remaining += entries_today_or_earlier.last.nil? ? 0 : entries_today_or_earlier.last.remaining_effort.to_f
        end
      end
      unless @sprint_data.empty?
        @sprint_data << ((total_remaining.zero? and entries_today_or_earlier.compact.empty?)? @sprint_data.last : total_remaining)
      else
        @sprint_data[0] = (total_remaining.zero? ? ideal.first : total_remaining)
      end
    end
    @sprint_data
  end
  
  def ideal_data
    issues = all_issues.select {|issue| issue.created_on.to_date <= dates.first }
    total_estimated = 0
    issues.each do |issue|
      estimated_effort_details = issue.journals.map(&:details).flatten.select {|detail| 'estimated_hours' == detail.prop_key}
      details_today_or_earlier = estimated_effort_details.select {|a| a.journal.created_on.to_date <= Time.now.to_date }
      first_estimated_effort = details_today_or_earlier.sort_by {|a| a.journal.created_on }.first
      total_estimated += first_estimated_effort.value.to_f unless first_estimated_effort.nil?    #issue.estimated_hours.to_f
    end
    @ideal_data = [total_estimated]
    days_left = dates.count - 1
    until days_left.zero?
      @ideal_data << (@ideal_data.last - (@ideal_data.last/days_left).to_f)
      days_left -= 1
    end
    @ideal_data
  end

  def data_and_dates
    @data1_and_dates = []
    @data2_and_dates = []
#    @data3_and_dates = []
    dates.each_with_index do |d, i|
#      @data1_and_dates << ["#{d} 6:00AM", labor_hours[i]]
      @data1_and_dates << ["#{d} 6:00AM", ideal[i]]
      @data2_and_dates << ["#{d} 6:00AM", sprint[i]]
    end
    [@data1_and_dates, @data2_and_dates].to_json       #, @data3_and_dates]
  end

  def self.sprint_has_started(id)
    !Version.find_by_id(id).sprint_start_date.nil? and (Version.find_by_id(id).sprint_start_date.to_time || 1.day.from_now) <= Time.now
  end

  def self.sprint_has_ended(version)
    effective_date = if version.effective_date.nil? or version.effective_date.to_date < version.sprint_start_date.to_date
        (version.sprint_start_date.to_date + 1.month)
      else
        version.effective_date.to_date
      end
    return effective_date <= Time.now.to_date
  end

#  ready to use for labor hours.
#  def labor_hours
#    #=IF(G77-(E4*E5)<=0,0,G77-(E4*E5))
#    resources = version.project.members.count
#    manhours = 8
#    period = dates.count - 1
#    velocity = resources * manhours * period
#    labor_hours = [velocity]
#    (1..(period)).each do |i|
#      tmp = labor_hours[i-1] - (resources * manhours)
#      labor_hours[i] = (tmp <= 0)? 0 : tmp
#    end
#    return labor_hours
#  end

end