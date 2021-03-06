module PivotalMiner
  class IssueCreator
    def initialize(label, issue_attributes, mapped_users)
      self.label = label
      self.issue_attributes = issue_attributes
      self.users = mapped_users
    end

    def run
      create_issue unless Issue.issue_exist?(story.id)
    end

    def status
      IssueStatus.find_by_name(ACCEPTED_STATUS) ||
          raise(WrongPivotalMinerConfiguration, "Can't find Redmine IssueStatus: #{ACCEPTED_STATUS} ")
    end

    def issue_params
      author_id = AnonymousUser.first.id
      priority_id = IssuePriority.first.try(:id)
      {
        subject: story.name,
        author_id: author.try(:id) || author_id,
        assigned_to_id: assignee.try(:id) || author.try(:id) || author_id,
        status_id: status.try(:id),
        priority_id: priority_id
      }
    end

    def story
      issue_attributes[:story]
    end

    def project_id
      issue_attributes[:project_id]
    end

    def author
      issue_attributes[:author]
    end

    def assignee
      issue_attributes[:assigned_to_id]
    end

    def mapping_params
      {
        tracker_id: tracker.try(:id),
        estimated_hours: estimated_hours
      }
    end

    def mapping
      @mapping ||= PivotalMiner.get_mapping(project_id, Unicode.downcase('sync_all_labels')) || PivotalMiner.get_mapping(project_id, Unicode.downcase(label))
    end

    def tracker
      Tracker.find_by_name(mapping.story_types[story.story_type])
    end

    def estimated_hours
      mapping.estimations[story.estimate.to_s].to_i
    end

    def add_comments(issue)
      story.notes.all.each do |note|
        user = User.get_by_pivotal_id(users[note.author]) || AnonymousUser.first
        issue.journals.create(notes: note.text, user: user)
      end
    end

    def create_issue
      return if mapping.try(:project).nil?
      return if tracker.nil?

      issue = mapping.project.issues.create!(issue_params.merge(mapping_params))

      PivotalMiner.sync_issue(issue, story.project_id, story.id)
      PivotalMiner.sync_task(issue)
    end

    private

    attr_accessor :label, :issue_attributes, :users
  end
end
