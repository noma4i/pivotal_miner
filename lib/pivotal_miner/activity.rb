module PivotalMiner
  class Activity

    def initialize(activity)
      self.activity = activity
    end

    def project_id
      activity['project']['id'] if activity['project']
    end

    def story_id
      activity['primary_resources'].select { |r| r['kind'] == 'story' }.first['id'] if activity['primary_resources']
    end

    def story_started?
      activity['highlight'] == 'started' && activity['kind'] == 'story_update_activity'
    end

    def is_a_task?
      activity['highlight'].include?('task')
    end

    def story_edited?
      activity['highlight'] == 'edited' && activity['kind'] == 'story_update_activity'
    end

    def author_name
      activity['performed_by']['name']
    end

    def author_id
      activity['performed_by']['id']
    end

    def author
      users = User.joins({custom_values: :custom_field})
        .where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_USER_ID, author_id)

      users.last
    end

    def project
      @pivotal_project ||= PivotalMiner::PivotalProject.new(project_id)
    end

    def new_value
      activity['changes'].select { |r| r['kind'] == 'story' }.first['new_values'] if activity['changes']
    end

    def performed_by
      activity['performed_by']
    end

    def changed_values
      activity['changes']
    end

    def story
      @story ||= project.story(story_id)
    end

    private

    attr_accessor :activity

  end
end