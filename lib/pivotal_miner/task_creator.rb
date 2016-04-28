module PivotalMiner
  class TaskCreator

    def initialize(task)
      self.label = label
      self.task_attributes = task
      self.issue_attributes = Issue.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_STORY_ID, task_attributes.story_id.to_s).delete_if{|i| i.pivotal_task_id > 0}.last
    end

    def run
      create_issue
    end

    def story
      task_attributes.story_id
    end

    def project_id
      task_attributes.project_id
    end

    def author
      task_attributes[:author]
    end

    def create_issue
      config_mappings = PivotalMiner::Configuration.new.map_config
      old_issue = Issue.find(issue_attributes.id)
      return unless old_issue.can_sync?(:redmine, 'tasks')
      issue = old_issue.dup
      issue.subject = task_attributes.description
      issue.tracker = Tracker.find_by_name(config_mappings['tasks'])
      attrs = issue.attributes.delete_if{|k,v| %w{lft rgt estimated_hours}.include?(k)}
      created_issue = Issue.create!(attrs)

      relation = IssueRelation.new(relation_type: 'relates')
      relation.issue_to_id = old_issue.id
      relation.issue_from_id = created_issue.id
      relation.save!

      PivotalMiner::TaskUpdater.new(created_issue.id, task_attributes).run
      PivotalMiner::CustomValuesCreator.new(project_id, story, created_issue.id, task_attributes.id, old_issue.pivotal_story_description).run
    end

    private

    attr_accessor :label, :task_attributes, :issue_attributes
  end
end
