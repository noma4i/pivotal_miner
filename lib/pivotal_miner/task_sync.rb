module PivotalMiner
  class TaskSync
    def initialize(issue, task)
      self.task = task
      self.issue = issue
    end

    def run
      update_task
    rescue => e
      raise PivotalTrackerError, "Can't sync the task id:#{task.id}. #{e}"
    end

    def update_task
      return unless issue.can_sync?(:pivotal, 'tasks')
      state = PivotalMiner::Configuration.new.map_config['task_states'][issue.status.name]
      task.update(:complete => state.eql?('closed'))
    end

    private

    attr_accessor :task, :issue
  end
end
