module PivotalMiner
  ACCEPTED_STATUS = 'Pending'
  CF_STORY_ID = 'Pivotal Story ID'
  CF_USER_ID = 'Pivotal User ID'
  CF_PROJECT_ID = 'Pivotal Project ID'
  CF_STORY_DESCRIPTION = 'Pivotal Story Description'

  WrongActivityData = Class.new(StandardError)
  MissingPivotalMinerConfig = Class.new(StandardError)
  MissingCredentials = Class.new(StandardError)
  WrongCredentials = Class.new(StandardError)
  MissingPivotalMinerMapping = Class.new(StandardError)
  WrongPivotalMinerConfiguration = Class.new(StandardError)
  PivotalTrackerError = Class.new(StandardError)

  class << self
    attr_writer :error_notification

    def missing_custom_fields
      fields = [
        CustomField.where(name: CF_STORY_ID).any?,
        CustomField.where(name: CF_USER_ID).any?,
        CustomField.where(name: CF_PROJECT_ID).any?,
        CustomField.where(name: CF_STORY_DESCRIPTION).any?
      ]

      fields.include?(false) ? true : false
    end

    def set_error_notification
      @error_notification = PivotalMiner::Configuration.new.error_notification
    end

    def error_notification
      @error_notification
    end

    def projects
      PivotalTracker::Project.all
    end

    def set_token(email)
      PivotalMiner::Authentication.set_token(email)
    end

    def project_labels(tracker_project_id)
      PivotalMiner::PivotalProject.new(tracker_project_id).labels
    end

    def read_activity(activity)
      PivotalMiner::ActivityReader.new(activity).run
    end

    def create_issues(activity)
      PivotalMiner::IssuesCreator.new(activity).run
    end

    def get_user_email(project_id, name)
      PivotalMiner::PivotalProject.new(project_id).participant_email(name)
    end

    def get_mapping(tracker_project_id, label)
      Mapping.where(['tracker_project_id=? AND label=? ', tracker_project_id, label.to_s]).first
    end

    def sync_story(issue, project_id, story_id)
      story = PivotalMiner::PivotalProject.new(project_id).story(story_id)
      PivotalMiner::StorySync.new(issue, story).run
    end

    def sync_task(issue, project_id, story_id, task_id)
      task = PivotalMiner::PivotalProject.new(project_id).story(story_id).tasks.find(task_id)
      PivotalMiner::TaskSync.new(issue, task).run
    end

    def api_v5
      TrackerApi::Client.new(token: PivotalMiner::Configuration.new.credentials('super_user').token)
    end

  end
end

