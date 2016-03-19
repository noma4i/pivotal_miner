module PivotalMiner
  class StorySync

    def initialize(issue, story)
      self.story = story
      self.issue = issue
    end

    def run
      update_story
    rescue => e
      raise PivotalTrackerError, "Can't sync the task id:#{story.id}. #{e}"
    end

    def update_story
      map_config = PivotalMiner::Configuration.new.map_config['story_states']
      states = Hash[map_config.to_a.collect(&:reverse)]
      new_state = states[issue.status.name]

      story.update(:current_state => new_state)
    end

    private

    attr_accessor :story, :issue
  end
end