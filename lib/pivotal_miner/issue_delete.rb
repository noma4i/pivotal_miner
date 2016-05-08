module PivotalMiner
  class IssueDelete
    def initialize(pivotal_story_id)
      self.issue_id = Issue.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_STORY_ID, pivotal_story_id.to_s).last.id
    end

    def run
      delete_issue(issue_id)
    end

    def update_task(issue_id)
      state = PivotalMiner::Configuration.new.map_config['removed_story']
      issue = Issue.find(issue_id)
      issue.update_column(:status_id, IssueStatus.find_by_name(state).try(:id))
    end

    private

    attr_accessor :issue_id
  end
end
