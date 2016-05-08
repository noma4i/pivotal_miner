module PivotalMiner
  ACCEPTED_STATUS = 'Pending'
  CF_STORY_ID = 'Pivotal Story ID'
  CF_TASK_ID = 'Pivotal Task ID'
  CF_USER_ID = 'Pivotal User ID'
  CF_PROJECT_ID = 'Pivotal Project ID'
  CF_STORY_DESCRIPTION = 'Pivotal Story Description'

  SYNC_TYPES = %w(tracker state priority milestones estimates owner tasks)

  WrongActivityData = Class.new(StandardError)
  MissingPivotalMinerConfig = Class.new(StandardError)
  MissingCredentials = Class.new(StandardError)
  WrongCredentials = Class.new(StandardError)
  MissingPivotalMinerMapping = Class.new(StandardError)
  WrongPivotalMinerConfiguration = Class.new(StandardError)
  PivotalTrackerError = Class.new(StandardError)

  ESTIMATES = {
    1 => 4,
    2 => 10,
    3 => 15,
    5 => 24,
    8 => 40,
    13 => 80,
    20 => 160
  }

  class << self
    attr_writer :error_notification

    def selective_sync(mapping, to, key)
      if to == :pivotal
        selective = mapping.sync_pivotal.present? && mapping.sync_pivotal[key] ? true : false
      elsif to == :redmine
        selective = mapping.sync_redmine.present? && mapping.sync_redmine[key] ? true : false
      end

      selective
    end

    def custom_fields_list
      [
        CF_STORY_ID,
        CF_TASK_ID,
        CF_USER_ID,
        CF_PROJECT_ID,
        CF_STORY_DESCRIPTION
      ]
    end

    def missing_custom_fields
      fields = [
        CustomField.where(name: CF_STORY_ID).any?,
        CustomField.where(name: CF_TASK_ID).any?,
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

    def get_mapping(tracker_project_id, label=nil)
      if label.present?
        Mapping.where(['tracker_project_id=? AND label=? ', tracker_project_id, label.to_s]).first
      else
        Mapping.where(tracker_project_id: tracker_project_id).last
      end
    end

    def sync_story(issue, project_id, story_id)
      PivotalMiner::StorySync.new(issue, project_id, story_id).update_story
    end

    def sync_issue(issue, project_id, story_id)
      PivotalMiner::StorySync.new(issue, project_id, story_id).update_issue
    end

    def sync_task(issue, project_id=nil, story_id=nil, task_id=nil)
      if project_id.present?
        task = PivotalMiner::PivotalProject.new(project_id).story(story_id).tasks.find(task_id)
        PivotalMiner::TaskSync.new(issue, task).run
      else
        PivotalMiner::TasksUpdater.new(issue).run
      end
    end

    def api_v5
      TrackerApi::Client.new(token: PivotalMiner::Configuration.new.credentials('super_user').token)
    end
  end
end