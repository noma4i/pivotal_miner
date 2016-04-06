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
      story_url.to_s + "\r\n" + activity.story.description.to_s
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

        issue.init_journal(user)
        issue.update_attributes!(params) if mapping_still_exists?(issue)
        issue.init_journal(user)
        PivotalMiner::CustomValuesCreator.new(activity.project_id, activity.story_id, issue.id, nil, description).run

        # map labels
        tags.map(&:upcase).each do |tag|
          if config_mappings['priority'].include?(tag)
            attrs = attrs.merge(priority_id: (IssuePriority.find_by_name(config_mappings['priority'][tag]).try(:id) || issue.priority).to_i)
          end

          if (/^M(\d*)/i =~ tag) === 0
            attrs = attrs.merge(fixed_version_id: (Version.find_by_id(tag.gsub('M','')) || issue.fixed_version).to_i)
          end
        end

        if new_state.present? && config_mappings['story_states'].include?(new_state.downcase)
          status = IssueStatus.find_by_name(config_mappings['story_states'][new_state.downcase])
          attrs = attrs.merge(status_id: status.to_i) if status.present?
        end

        if owned_by.present?
          owners = User.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_USER_ID, owned_by)
          attrs = attrs.merge(assigned_to_id: owners.first.to_i) if owners.present?
        end

        issue.update_attributes(attrs)

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