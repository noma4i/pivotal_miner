resources :mappings, except: :show

get 'mappings/update_labels', to: 'mappings#update_labels'
get 'mappings/import_users', to: 'mappings#import_users'
get 'mappings/pivotal_users', to: 'mappings#pivotal_users'
get 'mappings/pivotal_importer', to: 'mappings#pivotal_importer'
get 'mappings/update_user', to: 'mappings#update_user'
get 'mappings/update_from_pivotal', to: 'mappings#update_from_pivotal'