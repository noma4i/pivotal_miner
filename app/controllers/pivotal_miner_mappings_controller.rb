class PivotalMinerMappingsController < ApplicationController
  unloadable

  before_filter :require_admin
  before_filter :set_token
  before_filter :set_mapping, only: [:edit, :update, :destroy]

  def index
    @mappings = Mapping.all

    if PivotalMiner.missing_custom_fields
      @custom_fields_list = PivotalMiner.custom_fields_list
      render 'missing_fields'
    else
      render 'index'
    end
  end

  def new
    @mapping = Mapping.new
    @mapping.estimations = PivotalMiner::ESTIMATES
    @mapping.story_types = { 'feature' => 'Feature', 'bug' => 'Bug', 'chore' => 'Support' }
    @mapping.sync_pivotal = PivotalMiner::SYNC_TYPES.map{|t| {t => true}}.reduce(:merge)
    @mapping.sync_redmine = PivotalMiner::SYNC_TYPES.map{|t| {t => true}}.reduce(:merge)
    @projects = Project.all
    @tracker_projects = PivotalMiner.projects
    @labels = [['..choose..','']]
  end

  def edit
  end

  def create
    @mapping = Mapping.new(mapping_params)
    @mapping.tracker_project_id = tracker_project_id
    @mapping.tracker_project_name = PivotalTracker::Project.find(tracker_project_id.to_i).name
    if @mapping.save
      flash[:notice] = 'Mapping was successfully added.'
      redirect_to action: 'index'
    else
      flash[:error] = "Can't map these projects. #{error_message}"
      redirect_to action: 'new'
    end
  end

  def update
    if @mapping.update_attributes(estimations: params[:estimations], story_types: params[:story_types],       sync_redmine: params[:sync_redmine], sync_pivotal: params[:sync_pivotal])
      flash[:notice] = 'Updated successfully.'
      redirect_to action: 'index'
    else
      flash[:error] = "Can't save that configuration. #{error_message}"
      redirect_to action: 'new'
    end
  end

  def destroy
    if @mapping.destroy
      flash[:notice] = 'Mapping removed.'
    else
      flash[:error] = 'Mapping could not be removed.'
    end
    redirect_to action: 'index', project_id: @project
  end

  def update_labels
    @labels = PivotalMiner.project_labels(tracker_project_id.to_i)
    respond_to do |format|
      format.json { render json: @labels }
    end
  end

  def import_users
    connect_api_v5
    @pv_client.projects.each do |project|
      project.memberships.each do |member|
        user = User.find_by_mail(member.person.email)
        next unless user.present?

        field = user.available_custom_fields.inject{|field| field.name == 'Pivotal User ID'}
        CustomValue.create!(
          customized_type: 'Principal',
          custom_field_id: field.id,
          customized_id: user.id,
          value: member.person.id.to_i
        )
      end
    end

    flash[:notice] = 'Users Mapping imported from Pivotal!'

    redirect_to action: 'index'
  end

  def pivotal_importer
    connect_api_v5
    projects = PivotalMiner.projects
    projects.each do |project|
      redmine_mapping = Mapping.where(tracker_project_id: project.id)
      next unless redmine_mapping.any?

      members = get_members(project.id)
      project.stories.all.each do |story|
        labels = story.labels.to_s.split(',').push('sync_all_labels')
        attrs = {
          project_id: project.id,
          story: story,
          author: get_user(members[story.requested_by]),
          assigned_to: get_user(members[story.requested_by])
        }

        labels.each { |label| PivotalMiner::IssueCreator.new(label, attrs, members).run }
      end
    end

    flash[:notice] = 'Imported!'
    redirect_to action: 'index'
  end

  def pivotal_users
    connect_api_v5
    @users = []
    @redmine_users = User.all.map{|u| [u.name, u.id] }
    @pv_client.projects.each do |project|
      project.memberships.each do |member|
        next if @users.map(&:id).include?(member.person.id)
        @users << OpenStruct.new(
          id: member.person.id,
          fullname: member.person.name,
          username: member.person.username,
          email: member.person.email
        )
      end
    end
  end

  def update_user
    user_old = User.get_by_pivotal_id(params[:pivotal_id])
    user = User.find(params[:user_id])

    user_old.pivotal_id = nil if user_old.present?
    user.pivotal_id = params[:pivotal_id] if user.present?

    head :ok
  end

  def update_from_pivotal
    issue = Issue.find(params[:issue_id])
    issue.sync_from_pivotal

    flash[:notice] = 'Issue was updated from Pivotal!'

    redirect_to issue_path(issue)
  end

  private

  def get_members(project_id)
    members = []
    @pv_client.project(project_id).memberships.map{|m| members << Hash[ m.person.name, m.person.id] }

    members.reduce(:merge)
  end

  def get_user(pivotal_id)
    users = User.joins({custom_values: :custom_field})
      .where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_USER_ID, pivotal_id)

    users.last
  end

  def connect_api_v5
    @pv_client = PivotalMiner.api_v5
  end

  def set_token
    PivotalMiner::Authentication.set_token(User.current.mail)
  end

  def mapping_params
    {
      estimations: params[:estimations],
      story_types: params[:story_types],
      sync_redmine: params[:sync_redmine],
      sync_pivotal: params[:sync_pivotal],
      project_id: params[:mapping][:project_id],
      label: params[:mapping][:label]
    }
  end

  def tracker_project_id
    params[:tracker_project_id]
  end

  def set_mapping
    @mapping = Mapping.find(params[:id])
  end

  def error_message
    @mapping.errors.full_messages.to_sentence
  end
end
