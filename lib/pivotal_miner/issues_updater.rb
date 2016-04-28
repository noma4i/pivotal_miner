module PivotalMiner
  class IssuesUpdater

    def initialize(issues, activity)
      self.issues = issues
      self.activity = activity
    end

    def run
      story_update
    end

    def story_update
      update_issues(params_changed)
    end

    def description
      "#{story_url.to_s} \r\n\r\n #{activity.story.description.to_s}"
    end

    def params_changed
      if new_value['name'].present?
        { subject: new_value['name'] }
      end
    end

    def update_issues(params)
      config_mappings = PivotalMiner::Configuration.new.map_config
      tags = activity.new_value['labels'] || []
      new_state = activity.new_value['current_state'] || nil
      owned_by = activity.new_value['owned_by_id'] || nil

      issues.each do |item|
        issue = Issue.find(item.id)
        user = User.get_by_pivotal_id(performed_by['id'])
        attrs = {}
        maps = []

        issue.init_journal(user)
        desc_field_id = CustomField.find_by_name(PivotalMiner::CF_STORY_DESCRIPTION).id
        issue_description = CustomValue.joins(:custom_field).where(custom_fields: {id: desc_field_id}, customized_id: item.id).first.try(:value)

        if description.gsub(/\s+/, ' ').strip != issue_description.gsub(/\s+/, ' ').strip
          attrs = attrs.merge(custom_field_values: Hash[desc_field_id, description.to_s.strip])
        end

        issue.update_attributes!(params) if mapping_still_exists?(issue)
        issue.init_journal(user)

        attrs = attrs.merge issue.pivotal_label_sync(tags)

        tags + ['sync_all_labels'].map do |label|
          maps << PivotalMiner.get_mapping(activity.story.project_id, Unicode.downcase(label))
        end
        mapping = maps.compact.last

        attrs = attrs.merge(estimated_hours: mapping.estimations[activity.story.estimate.to_s].to_i) if mapping.present?

        if new_state.present? && config_mappings['story_states'].include?(new_state.downcase)
          status = IssueStatus.find_by_name(config_mappings['story_states'][new_state.downcase])
          attrs = attrs.merge(status_id: status.try(:id)) if status.present? && issue.can_sync?(:redmine, 'state')
        end

        if owned_by.present?
          owners = User.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_USER_ID, owned_by)

          attrs = attrs.merge(assigned_to_id: owners.first.id.to_i) if owners.present? && issue.can_sync?(:redmine, 'owner')
        end

        issue.update_attributes(attrs)

        PivotalMiner::CustomValuesCreator.new(activity.project_id, activity.story_id, issue.id, nil, description).run
        PivotalMiner::TasksUpdater.new(issue).run
      end
    end

    def mapping_still_exists?(issue)
      issue.project.mappings.where(tracker_project_id: issue.pivotal_project_id).present? rescue false
    end

    private

    attr_accessor :issues, :activity

    def story_url
      activity.story.url
    end

    def new_value
      activity.new_value
    end

    def performed_by
      activity.performed_by
    end

    def pivotal_project_id
      activity.acproject_id
    end
  end
end