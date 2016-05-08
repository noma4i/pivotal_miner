module PivotalMiner
  class ActivityReader
    def initialize(activity)
      self.activity = activity
    end

    def run
      return if activity.is_a_task?

      if issues.present?
        update_issues
      else
        PivotalMiner::IssuesCreator.new(activity).run
      end
    end

    def update_issues
      PivotalMiner::IssuesUpdater.new(issues, activity).run
    end

    def issues
      issues ||= Issue.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_STORY_ID, activity.story_id.to_s)
      @issues = issues.delete_if{|i| i.pivotal_task_id > 0}
    end

    private

    attr_accessor :activity
  end
end
