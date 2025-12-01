require 'redmine'

RISKS_VERSION_NUMBER = '2.0.0'

Redmine::Plugin.register :redmine_risks do
  name 'Risks'
  author 'eXolnet'
  description 'Manage the results of the qualitative risk analysis, quantitative risk analysis, and risk response planning.'
  version RISKS_VERSION_NUMBER
  url 'https://github.com/eXolnet/redmine_risks'
  author_url 'https://www.exolnet.com'

  requires_redmine :version_or_higher => '5.0'

  # Risk Management parent menu (no controller - just a container)
  menu :project_menu, :risk_management, { :controller => 'risks', :action => 'index' }, :caption => :label_risk_management, :before => :settings, :param => :project_id

  # Child menus under Risk Management
  menu :project_menu, :risks, { :controller => 'risks', :action => 'index' }, :caption => :label_risks, :param => :project_id, :parent => :risk_management
  menu :project_menu, :risk_dashboard, { :controller => 'risk_dashboard', :action => 'project' }, :caption => :label_risk_dashboard, :param => :project_id, :parent => :risk_management
  menu :project_menu, :risk_settings, { :controller => 'risk_project_settings', :action => 'show' }, :caption => :label_risk_settings, :param => :project_id, :parent => :risk_management, :if => Proc.new { |p| User.current.allowed_to?(:manage_risk_settings, p) }

  # New risk in the "+" menu
  menu :project_menu, :new_risk, { :controller => 'risks', :action => 'new' }, :caption => :label_new_risk, :after => :new_wiki_sub, :param => :project_id, :parent => :new_object

  # menu :top_menu, :risk_dashboard, { :controller => 'risk_dashboard', :action => 'index' }, :caption => :label_risk_dashboard, :if => Proc.new { User.current.admin? }

  project_module :risks do
    permission :view_risks,            { :risks => [:index, :show] }, :read => true
    permission :add_risks,             { :risks => [:new, :create, :commit] }
    permission :edit_risks,            { :risks => [:edit, :update] }
    permission :delete_risks,          { :risks => [:destroy] }, :require => :member
    permission :view_risk_dashboard,   { :risk_dashboard => [:project] }, :read => true

    # Related issues
    permission :manage_risk_relations, {}

    # Risk activities
    permission :manage_risk_activities, { :risk_activities => [:new, :create, :edit, :update, :destroy] }

    # Risk settings
    permission :manage_risk_settings, { :risk_project_settings => [:show, :update] }

    # Risk import
    permission :import_risks, { :risk_imports => [:new, :create, :template] }
  end

  # Pulls are added to the activity view
  activity_provider :risks, :class_name => ['Risk', 'Journal']
end

require File.dirname(__FILE__) + '/lib/redmine_risks'
