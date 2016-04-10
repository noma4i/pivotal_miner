require 'sinatra'

class PivotalHandler < Sinatra::Base

  post '/pivotal_activity.json' do
    pivotal_body = JSON.parse(request.body.read.to_s)
    return [202, 'It is not a correct Pivotal Tracker message'] if pivotal_body['kind'].nil?
    if %w(story_update_activity story_create_activity).include?(pivotal_body['kind'])
      begin
        PivotalMiner.read_activity(PivotalMiner::Activity.new(pivotal_body))
      # rescue => e
        # PivotalMinerMailer.error_mail("Error while reading activity message from Pivotal Tracker: #{e}").deliver
      end

      return [200, 'Got the activity']
    elsif %w(task_update_activity task_create_activity).include?(pivotal_body['kind'])
      activity = PivotalMiner::Activity.new(pivotal_body)
      issue = Issue.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_STORY_ID, activity.story.id.to_s).last

      PivotalMiner::TasksUpdater.new(issue).run

      return [200, 'Got Tasks']
    elsif pivotal_body['kind'] == 'task_delete_activity'
      pivotal_body['changes'].each do |pv|
        PivotalMiner::TasksDelete.new(pv['id'].to_i).run if pv['change_type'] == 'delete'
      end
      return [200, 'Delte Task']
    else
      return [202, 'Not supported event_type']
    end
  end
end