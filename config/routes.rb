# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/risks/preview/new/:project_id', :to => 'risks#preview', :as => 'preview_new_risk', :via => [:get, :post, :put, :patch]
match '/risks/preview/edit/:id', :to => 'risks#preview', :as => 'preview_edit_risk', :via => [:get, :post, :put, :patch]
post '/risks/:id/quoted', :to => 'risks#quoted', :id => /\d+/, :as => 'quoted_risk'

match '/risks/context_menu', :to => 'context_menus#risks', :as => 'risks_context_menu', :via => [:get, :post]

# Dashboard routes
get '/risk_dashboard', :to => 'risk_dashboard#index', :as => 'risk_dashboard'
get '/projects/:project_id/risk_dashboard', :to => 'risk_dashboard#project', :as => 'project_risk_dashboard'

# Risk reports routes
get '/projects/:project_id/risk_reports', :to => 'risk_reports#index', :as => 'project_risk_reports'
get '/projects/:project_id/risk_reports/risk_list', :to => 'risk_reports#risk_list', :as => 'project_risk_list_report'
get '/projects/:project_id/risk_reports/dashboard', :to => 'risk_reports#dashboard', :as => 'project_risk_dashboard_report'
get '/projects/:project_id/risk_reports/registry', :to => 'risk_reports#registry', :as => 'project_risk_registry_report'

# Risk project settings routes
get '/projects/:project_id/risk_settings', :to => 'risk_project_settings#show', :as => 'project_risk_settings'
patch '/projects/:project_id/risk_settings', :to => 'risk_project_settings#update'
delete '/projects/:project_id/risk_settings/delete_logo', :to => 'risk_project_settings#delete_logo', :as => 'delete_risk_logo'

# Impact/Probability point settings routes
post '/projects/:project_id/risk_settings/initialize_point_settings', :to => 'risk_project_settings#initialize_point_settings', :as => 'initialize_risk_point_settings'
patch '/projects/:project_id/risk_settings/update_impact_points', :to => 'risk_project_settings#update_impact_points', :as => 'update_risk_impact_points'
patch '/projects/:project_id/risk_settings/update_probability_points', :to => 'risk_project_settings#update_probability_points', :as => 'update_risk_probability_points'
post '/projects/:project_id/risk_settings/add_impact_point', :to => 'risk_project_settings#add_impact_point', :as => 'add_risk_impact_point'
post '/projects/:project_id/risk_settings/add_probability_point', :to => 'risk_project_settings#add_probability_point', :as => 'add_risk_probability_point'
delete '/projects/:project_id/risk_settings/delete_impact_point/:setting_id', :to => 'risk_project_settings#delete_impact_point', :as => 'delete_risk_impact_point'
delete '/projects/:project_id/risk_settings/delete_probability_point/:setting_id', :to => 'risk_project_settings#delete_probability_point', :as => 'delete_risk_probability_point'

# Strategy settings routes
post '/projects/:project_id/risk_settings/initialize_strategy_settings', :to => 'risk_project_settings#initialize_strategy_settings', :as => 'initialize_risk_strategy_settings'
patch '/projects/:project_id/risk_settings/update_strategy_settings', :to => 'risk_project_settings#update_strategy_settings', :as => 'update_risk_strategy_settings'
post '/projects/:project_id/risk_settings/add_strategy_setting', :to => 'risk_project_settings#add_strategy_setting', :as => 'add_risk_strategy_setting'
delete '/projects/:project_id/risk_settings/delete_strategy_setting/:setting_id', :to => 'risk_project_settings#delete_strategy_setting', :as => 'delete_risk_strategy_setting'

# Probability entry settings routes
post '/projects/:project_id/risk_settings/initialize_probability_entry_settings', :to => 'risk_project_settings#initialize_probability_entry_settings', :as => 'initialize_risk_probability_entry_settings'
patch '/projects/:project_id/risk_settings/update_probability_entry_settings', :to => 'risk_project_settings#update_probability_entry_settings', :as => 'update_risk_probability_entry_settings'
post '/projects/:project_id/risk_settings/add_probability_entry_setting', :to => 'risk_project_settings#add_probability_entry_setting', :as => 'add_risk_probability_entry_setting'
delete '/projects/:project_id/risk_settings/delete_probability_entry_setting/:setting_id', :to => 'risk_project_settings#delete_probability_entry_setting', :as => 'delete_risk_probability_entry_setting'

# Impact entry settings routes
post '/projects/:project_id/risk_settings/initialize_impact_entry_settings', :to => 'risk_project_settings#initialize_impact_entry_settings', :as => 'initialize_risk_impact_entry_settings'
patch '/projects/:project_id/risk_settings/update_impact_entry_settings', :to => 'risk_project_settings#update_impact_entry_settings', :as => 'update_risk_impact_entry_settings'
post '/projects/:project_id/risk_settings/add_impact_entry_setting', :to => 'risk_project_settings#add_impact_entry_setting', :as => 'add_risk_impact_entry_setting'
delete '/projects/:project_id/risk_settings/delete_impact_entry_setting/:setting_id', :to => 'risk_project_settings#delete_impact_entry_setting', :as => 'delete_risk_impact_entry_setting'

# Treatment plan settings routes
post '/projects/:project_id/risk_settings/initialize_treatment_plan_settings', :to => 'risk_project_settings#initialize_treatment_plan_settings', :as => 'initialize_risk_treatment_plan_settings'
patch '/projects/:project_id/risk_settings/update_treatment_plan_settings', :to => 'risk_project_settings#update_treatment_plan_settings', :as => 'update_risk_treatment_plan_settings'
post '/projects/:project_id/risk_settings/add_treatment_plan_setting', :to => 'risk_project_settings#add_treatment_plan_setting', :as => 'add_risk_treatment_plan_setting'
delete '/projects/:project_id/risk_settings/delete_treatment_plan_setting/:setting_id', :to => 'risk_project_settings#delete_treatment_plan_setting', :as => 'delete_risk_treatment_plan_setting'

# Project-level entry lists routes (vulnerabilities, consequences, counter-measures)
post '/projects/:project_id/risk_settings/add_vulnerability_entry', :to => 'risk_project_settings#add_vulnerability_entry', :as => 'add_risk_vulnerability_entry'
delete '/projects/:project_id/risk_settings/delete_vulnerability_entry/:entry_id', :to => 'risk_project_settings#delete_vulnerability_entry', :as => 'delete_risk_vulnerability_entry'
post '/projects/:project_id/risk_settings/add_consequence_entry', :to => 'risk_project_settings#add_consequence_entry', :as => 'add_risk_consequence_entry'
delete '/projects/:project_id/risk_settings/delete_consequence_entry/:entry_id', :to => 'risk_project_settings#delete_consequence_entry', :as => 'delete_risk_consequence_entry'
post '/projects/:project_id/risk_settings/add_counter_measure_entry', :to => 'risk_project_settings#add_counter_measure_entry', :as => 'add_risk_counter_measure_entry'
delete '/projects/:project_id/risk_settings/delete_counter_measure_entry/:entry_id', :to => 'risk_project_settings#delete_counter_measure_entry', :as => 'delete_risk_counter_measure_entry'

resources :projects do
  resources :risks, :only => [:index, :new, :create] do
    collection do
      delete 'destroy_all'
    end
  end
  resources :risk_imports, :only => [:new, :create] do
    collection do
      get 'template'
    end
  end

  # Registry management routes (project-scoped)
  resources :risk_category_entries, :except => [:show]
  resources :risk_registries, :except => [:show]
  resources :risk_areas, :except => [:show]
end

resources :risks, :except => [:index, :new, :create] do
  post   'issues', :to => 'risk_issues#create'
  delete 'issues/:issue_id', :to => 'risk_issues#destroy'

  resources :activities, controller: 'risk_activities', except: [:index] do
    resources :notes, controller: 'risk_activity_notes', only: [:create, :destroy]
  end

  collection do
    post 'bulk_update'
  end
end

match '/risks', :controller => 'risks', :action => 'destroy', :via => :delete