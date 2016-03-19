module PivotalMiner
  class IssuesCreator

    def initialize(activity)
      self.activity = activity
    end

    def story
      activity.story
    end

    def labels
      story.labels.to_s.split(',') || ['sync_all_labels']
    end

    def issue_attributes
      {
        project_id: activity.project_id,
        story: story,
        author: activity.author
      }
    end

    def run
      pv_client = PivotalMiner.api_v5
      members = []
      pv_client.project(project_id).memberships.map{|m| members << Hash[ m.person.name, m.person.id] }
      labels.each { |label| IssueCreator.new(label, issue_attributes, members.reduce(:merge)).run }
    end

    private

    attr_accessor :activity
  end
end
