module PivotalMiner
  class TaskUpdater

    def initialize(existing_task_id, task)
      self.issue_id = existing_task_id
      self.is_completed = task.complete
      self.task_attributes = task
    end

    def run
      update_issue
    end

    def update_issue
      task = Issue.find(issue_id)
      parent_issue = task.relations.first.try(:issue_to)
      task.subject = task_attributes.description
      task.fixed_version = parent_issue.fixed_version
      if is_completed
        task.status = IssueStatus.find_by_name('Closed')
      else
        task.status = IssueStatus.find_by_name('Pending')
      end
      task.save!
    end

    private

    attr_accessor :label, :task_attributes, :issue_id, :is_completed
  end
end
