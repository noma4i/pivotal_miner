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
        issue.update_attributes!(params) if mapping_still_exists?(issue)
        PivotalMiner::CustomValuesCreator.new(activity.project_id, activity.story_id, issue.id, nil, description).run

        # map labels
        tags.each do |tag|
          if config_mappings['priority'].include?(tag.upcase)
            issue.priority = IssuePriority.find_by_name(config_mappings['priority'][tag.upcase]) || issue.priority
          end

          if (/^M(\d*)/i =~ tag.upcase) === 0
            issue.fixed_version = Version.find(tag.upcase.gsub('M',''))
          end
        end

        if new_state.present? && config_mappings['story_states'].include?(new_state.downcase)
          status = IssueStatus.find_by_name(config_mappings['story_states'][new_state.downcase])
          issue.status = status if status.present?
        end

        if owned_by.present?
          owners = User.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_USER_ID, owned_by)

          issue.assigned_to = owners.first if owners.present?
        end

        issue.save! if issue.changed?

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

    def pivotal_project_id
      activity.acproject_id
    end
  end
end