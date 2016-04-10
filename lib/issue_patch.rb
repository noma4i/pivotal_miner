require_dependency 'issue'

module IssuePatch

  def self.included(klass) # :nodoc:

    klass.class_eval do
      unloadable
      before_update :sync_states

      def pivotal_custom_value(name)
        CustomValue.joins(:custom_field).where(custom_fields: {name: name}, customized_id: self.id).first rescue nil
      end

      def pivotal_project_id=(project_id)
        pivotal_custom_value(PivotalMiner::CF_PROJECT_ID).update_attributes!(value: project_id.to_s)
      end

      def pivotal_project_id
        pivotal_custom_value(PivotalMiner::CF_PROJECT_ID).try(:value).to_i
      end

      def pivotal_story_id=(story_id)
        pivotal_custom_value(PivotalMiner::CF_STORY_ID).update_attributes!(value: story_id.to_s)
      end

      def pivotal_story_id
        pivotal_custom_value(PivotalMiner::CF_STORY_ID).try(:value).to_i
      end

      def pivotal_task_id
        pivotal_custom_value(PivotalMiner::CF_TASK_ID).try(:value).to_i
      end

      def pivotal_story_description
        pivotal_custom_value(PivotalMiner::CF_STORY_DESCRIPTION).try(:value)
      end

      def issue_closed?
        status_id_changed? && status.is_closed?
      end

      def pivotal_assigned?
        pivotal_story_id != 0 && pivotal_project_id != 0
      end

      def pivotal_task_assigned?
        pivotal_task_id != 0 && pivotal_project_id != 0
      end

      def self.issue_exist?(pivotal_id)
        issues ||= Issue.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_STORY_ID, pivotal_id)

        issues.count > 0 ? true : false
      end

      def pivotal_label_sync(tags)
        config_mappings = PivotalMiner::Configuration.new.map_config
        attrs = {}
        tags.map(&:upcase).each do |tag|
          if config_mappings['priority'].include?(tag)
            attrs = attrs.merge(priority_id: (IssuePriority.find_by_name(config_mappings['priority'][tag]).try(:id) || issue.priority).to_i)
          end

          if (/^M(\d*)/i =~ tag) === 0
            attrs = attrs.merge(fixed_version_id: (Version.find_by_id(tag.gsub('M','')).try(:id) || issue.fixed_version_id))
          end
        end

        attrs
      end

      def sync_from_pivotal
        PivotalMiner.sync_issue(self, pivotal_project_id, pivotal_story_id) if pivotal_assigned? && !pivotal_task_assigned?
      end

      def sync_states
        return unless self.changes.include?('status_id') || self.changes.include?('priority_id') || self.changes.include?('fixed_version_id')
        PivotalMiner.sync_story(self, pivotal_project_id, pivotal_story_id) if pivotal_assigned? && !pivotal_task_assigned?
        PivotalMiner.sync_task(self, pivotal_project_id, pivotal_story_id, pivotal_task_id) if pivotal_assigned? && pivotal_task_assigned?
      rescue => e
        error_message = "Error while Syncing Story ID:'#{pivotal_story_id}' in Project ID:'#{pivotal_project_id}' : #{e}"
        raise error_message
      end
    end
  end
end
