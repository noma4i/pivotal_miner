module PivotalMiner
  class StorySync

    def initialize(issue, project_id, story_id)
      self.story = PivotalMiner::PivotalProject.new(project_id).story(story_id)
      self.issue = issue
    end

    def update_issue
      config_mappings = PivotalMiner::Configuration.new.map_config

      description =  "#{story.url} --- #{story.description.to_s}"
      PivotalMiner::CustomValuesCreator.new(story.project_id, story.id, issue.id, nil, description).run
      status = IssueStatus.find_by_name(config_mappings['story_states'][story.current_state])
      story_type = Tracker.find_by_name(issue.project.mappings.last.story_types[story.story_type]) || issue.tracker

      attrs = issue.pivotal_label_sync(story.labels.split(','))
      attrs = attrs.merge(subject: story.name) if status.present?
      attrs = attrs.merge(status_id: status.try(:id)) if status.present?
      attrs = attrs.merge(tracker_id: story_type.try(:id))
      attrs.to_a.map{|attr| issue.update_column(attr.first, attr.last)}
    end

    def update_story
      states = PivotalMiner::Configuration.new.map_config['issue_states']
      new_state = states[issue.status.name] || story.current_state

      tags = story.labels.split(',').map(&:upcase)
      priority_tags = PivotalMiner::Configuration.new.map_config['priority']
      new_tag = priority_tags.invert[issue.priority.name]
      version = issue.changes['fixed_version_id']

      priority_tags.keys.map(&:upcase).each do |p|
        tags -= ["#{p}"]
      end

      tags << new_tag

      if version.present?
        tags << "M#{version.last}"
        tags -= ["M#{version.first}"] if version.first.present?
      end

      story_reload = PivotalMiner::PivotalProject.new(story.project_id).story(story.id)
      story_reload.update labels: tags
      if new_state != story.current_state
        story_reload = PivotalMiner::PivotalProject.new(story.project_id).story(story.id)
        story_reload.update current_state: new_state
      end
    end

    private

    attr_accessor :story, :issue
  end
end