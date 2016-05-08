module PivotalMiner
  class StorySync
    def initialize(issue, project_id, story_id)
      self.story = PivotalMiner::PivotalProject.new(project_id).story(story_id)
      self.issue = issue
    end

    def labels
      story.labels.to_s.split(',').push('sync_all_labels')
    end

    def mapping
      maps = []
      labels.map do |label|
        maps << PivotalMiner.get_mapping(story.project_id, Unicode.downcase(label))
      end

      maps.compact.last
    end

    def update_issue
      config_mappings = PivotalMiner::Configuration.new.map_config

      description =  "#{story.url} \r\n\r\n #{story.description.to_s}"
      PivotalMiner::CustomValuesCreator.new(story.project_id, story.id, issue.id, nil, description).run
      status = IssueStatus.find_by_name(config_mappings['story_states'][story.current_state])
      story_type = Tracker.find_by_name(issue.project.mappings.last.story_types[story.story_type]) || issue.tracker

      attrs = issue.pivotal_label_sync(labels)
      attrs = attrs.merge(subject: story.name) if status.present?
      attrs = attrs.merge(status_id: status.try(:id)) if status.present? && issue.can_sync?(:redmine, 'state')
      attrs = attrs.merge(tracker_id: story_type.try(:id)) if issue.can_sync?(:redmine, 'tracker')

      if issue.can_sync?(:redmine, 'owner')
        owners = User.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_USER_ID, story.owned_by)
        attrs = attrs.merge(assigned_to_id: owners.first.id.to_i) if owners.present? && issue.can_sync?(:redmine, 'owner')
      end

      attrs = attrs.merge(estimated_hours: mapping.estimations[story.estimate.to_s].to_i) if mapping.present? && issue.can_sync?(:redmine, 'estimates')

      attrs.to_a.map{ |attr| issue.update_column(attr.first, attr.last) }
    end

    def update_story
      states = PivotalMiner::Configuration.new.map_config['issue_states']
      new_state = states[issue.status.name] || story.current_state

      tags = story.labels.split(',').map(&:upcase)
      if issue.can_sync?(:pivotal, 'priority')
        priority_tags = PivotalMiner::Configuration.new.map_config['priority']
        priority_tags.keys.map(&:upcase).each do |p|
          tags -= ["#{p}"]
        end
        tags << priority_tags.invert[issue.priority.name]
      end

      if issue.can_sync?(:pivotal, 'milestones')
        version = issue.changes['fixed_version_id']

        if version.present?
          tags << "M#{version.last}"
          tags -= ["M#{version.first}"] if version.first.present?
        end
      end

      reload_and_update(labels: tags) if story.labels.split(',').map(&:upcase) != tags
      reload_and_update(estimate: mapping.estimations.invert[issue.estimated_hours.to_i.to_s]) if issue.changes.include?('estimated_hours') && issue.can_sync?(:pivotal, 'estimates')

      reload_and_update(current_state: new_state) if issue.changes.include?('status') && issue.can_sync?(:pivotal, 'state')
    end

    protected

    def reload_and_update(params)
      story_reload = PivotalMiner::PivotalProject.new(story.project_id).story(story.id)
      story_reload.update params
    end

    attr_accessor :story, :issue
  end
end
