class AddSyncTypesToMappings < ActiveRecord::Migration
  def self.up
    add_column :mappings, :sync_pivotal, :text
    add_column :mappings, :sync_redmine, :text
  end

  def self.down
    remove_column :mappings, :sync_pivotal
    remove_column :mappings, :sync_redmine
  end
end
