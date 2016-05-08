resources :pivotal_miner_mappings, except: :show

get 'pivotal_miner_mappings/update_labels', to: 'pivotal_miner_mappings#update_labels'
get 'pivotal_miner_mappings/import_users', to: 'pivotal_miner_mappings#import_users'
get 'pivotal_miner_mappings/pivotal_users', to: 'pivotal_miner_mappings#pivotal_users'
get 'pivotal_miner_mappings/pivotal_importer', to: 'pivotal_miner_mappings#pivotal_importer'
get 'pivotal_miner_mappings/update_user', to: 'pivotal_miner_mappings#update_user'
get 'pivotal_miner_mappings/update_from_pivotal', to: 'pivotal_miner_mappings#update_from_pivotal'