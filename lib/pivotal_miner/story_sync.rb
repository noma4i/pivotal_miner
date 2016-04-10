module PivotalMiner
  class StorySync

    def initialize(issue, project_id, story_id)
      self.story = PivotalMiner::PivotalProject.new(project_id).story(story_id)
      self.issue = issue
    end

    def update_issue
      config_mappings = PivotalMiner::Configuration.new.map_config

      description = story.url + "\r\n\r\n" + story.description.to_s
      PivotalMiner::CustomValuesCreator.new(story.project_id, story.id, issue.id, nil, description).run
      status = IssueStatus.find_by_name(config_mappings['story_states'][story.current_state])

      attrs = issue.pivotal_label_sync(story.labels.split(','))
      attrs = attrs.merge(status_id: status.try(:id)) if status.present?

      attrs.to_a.map{|attr| issue.update_column(attr.first, attr.last)}
    end

    def update_story
      map_config = PivotalMiner::Configuration.new.map_config['story_states']
      states = Hash[map_config.to_a.collect(&:reverse)]
      new_state = states[issue.status.name]

      tags = story.labels.split(',').map(&:upcase)
      priority_tags = PivotalMiner::Configuration.new.map_config['priority']
      new_tag = priority_tags.invert[issue.priority.name]
      version = issue.changes['fixed_version_id']
      tags_to_update = (tags - priority_tags.keys).push(new_tag)

      if version.present?
        tags_to_update << "M#{version.last}"
        tags_to_update -= ["M#{version.first}"] if version.first.present?
      end

      story_reload = PivotalMiner::PivotalProject.new(story.project_id).story(story.id)
      story_reload.update(current_state: new_state, labels: tags_to_update)
    end

    private

    attr_accessor :story, :issue
  end
end