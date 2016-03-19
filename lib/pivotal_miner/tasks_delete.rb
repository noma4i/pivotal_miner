module PivotalMiner
  class TasksDelete

    def initialize(pivotal_task_id)
      self.issue_id = Issue.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", 'Pivotal Task ID', pivotal_task_id.to_s).last.id
    end

    def run
      update_task(issue_id)
    end

    def update_task(issue_id)
      state = PivotalMiner::Configuration.new.map_config['removed_task']
      issue = Issue.find(issue_id)
      issue.update_column(:status_id, IssueStatus.find_by_name(state).try(:id))
    end

    private

    attr_accessor :issue_id
  end
end
