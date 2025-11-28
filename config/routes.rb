# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/risks/preview/new/:project_id', :to => 'risks#preview', :as => 'preview_new_risk', :via => [:get, :post, :put, :patch]
match '/risks/preview/edit/:id', :to => 'risks#preview', :as => 'preview_edit_risk', :via => [:get, :post, :put, :patch]
post '/risks/:id/quoted', :to => 'risks#quoted', :id => /\d+/, :as => 'quoted_risk'

match '/risks/context_menu', :to => 'context_menus#risks', :as => 'risks_context_menu', :via => [:get, :post]

# Dashboard routes
get '/risk_dashboard', :to => 'risk_dashboard#index', :as => 'risk_dashboard'
get '/projects/:project_id/risk_dashboard', :to => 'risk_dashboard#project', :as => 'project_risk_dashboard'

# Risk project settings routes
get '/projects/:project_id/risk_settings', :to => 'risk_project_settings#show', :as => 'project_risk_settings'
patch '/projects/:project_id/risk_settings', :to => 'risk_project_settings#update'

resources :projects do
  resources :risks, :only => [:index, :new, :create]
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