module PivotalMiner
  class TasksUpdater

    def initialize(issue)
      self.issue = Issue.find(issue.id)
    end

    def run
      update_tasks(issue)
    end

    def update_tasks(issue)
      project = PivotalMiner::PivotalProject.new(issue.pivotal_project_id)
      tasks = project.story(issue.pivotal_story_id).tasks.all || []

      tasks.each do |task|
        existing_task = Issue.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", 'Pivotal Task ID', task.id.to_s).last
        if existing_task.present?
          PivotalMiner::TaskUpdater.new(existing_task.id, task).run
        else
          PivotalMiner::TaskCreator.new(task).run
        end
      end
    end

    private

    attr_accessor :issue
  end
end
