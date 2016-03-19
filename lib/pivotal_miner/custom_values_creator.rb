module PivotalMiner
  class CustomValuesCreator

    def initialize(project_id, story_id, issue_id, task_id, description)
      self.project_id = project_id
      self.story_id = story_id
      self.issue_id = issue_id
      self.task_id = task_id
      self.pv_description = description
    end

    def run
      create_custom_values
    end

    def custom_field_pivotal_story_id
      CustomField.find_by_name(PivotalMiner::CF_STORY_ID).id
    end

    def custom_field_pivotal_project_id
      CustomField.find_by_name(PivotalMiner::CF_PROJECT_ID).id
    end

    def custom_field_pivotal_task_id
      CustomField.find_by_name(PivotalMiner::CF_TASK_ID).id
    end

    def custom_field_pivotal_story_description
      CustomField.find_by_name(PivotalMiner::CF_STORY_DESCRIPTION).id
    end

    def create_custom_values
      story_field = CustomValue.joins(:custom_field)
        .where(custom_fields: {id: custom_field_pivotal_story_id}, customized_id: issue_id).first
      project_field = CustomValue.joins(:custom_field)
        .where(custom_fields: {id: custom_field_pivotal_project_id}, customized_id: issue_id).first
      task_field = CustomValue.joins(:custom_field)
        .where(custom_fields: {id: custom_field_pivotal_task_id}, customized_id: issue_id).first
      description_field = CustomValue.joins(:custom_field)
        .where(custom_fields: {id: custom_field_pivotal_story_description}, customized_id: issue_id).first
      if story_field.present? && project_field.present?
        story_field.update_column(:value, story_id.to_i)
        project_field.update_column(:value, project_id.to_i)
        task_field.update_column(:value, task_id.to_i)
        description_field.update_column(:value, pv_description)
      else
        CustomValue.create!(
          customized_type: 'Issue',
          custom_field_id: custom_field_pivotal_project_id,
          customized_id: issue_id,
          value: project_id.to_i
        )

        CustomValue.create!(
          customized_type: 'Issue',
          custom_field_id: custom_field_pivotal_story_id,
          customized_id: issue_id,
          value: story_id.to_i
        ) unless task_id.present?

        CustomValue.create!(
          customized_type: 'Issue',
          custom_field_id: custom_field_pivotal_task_id,
          customized_id: issue_id,
          value: task_id.to_i
        )

        CustomValue.create!(
          customized_type: 'Issue',
          custom_field_id: custom_field_pivotal_story_description,
          customized_id: issue_id,
          value: pv_description
        )
      end
    end

    def add_comments
      story.notes.all.each do |note|
        user = User.find_by_mail(get_user_email(story.project_id, note.author))
        journal = issue.journals.new(notes: note.text)
        journal.user_id = user.id unless user.nil?
        journal.save
      end
    end

    private

    attr_accessor :project_id, :story_id, :issue_id, :task_id, :pv_description
  end
end
