require 'redmine'
require 'pivotal_miner'
require 'unicode'
require 'pivotal_miner/hooks'

Rails.logger.info 'Starting PivotalMiner Plugin for Redmine'

require_dependency 'project_patch'
require_dependency 'issue_patch'

Rails.application.config.middleware.insert_before(Rack::Runtime, 'PivotalHandler' )

Issue.send(:include, IssuePatch)
Project.send(:include, ProjectPatch)
User.send(:include, UserPatch)

PivotalMiner.set_error_notification

Redmine::Plugin.register :pivotal_miner do
  name 'Redmine PivotalMiner plugin'
  author 'Alexander Tsirel'
  description 'Seamless Pivotal Tracker Two-Way sync'
  version '1.3.0'

  menu :admin_menu, :pivotal_miner, { controller: :pivotal_miner_mappings, action: 'index' }, caption: 'Pivotal Miner', last: true
end
