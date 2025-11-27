require 'redmine'

RISKS_VERSION_NUMBER = '1.9.0'

Redmine::Plugin.register :redmine_risks do
  name 'Risks'
  author 'eXolnet'
  description 'Manage the results of the qualitative risk analysis, quantitative risk analysis, and risk response planning.'
  version RISKS_VERSION_NUMBER
  url 'https://github.com/eXolnet/redmine_risks'
  author_url 'https://www.exolnet.com'

  requires_redmine :version_or_higher => '5.0'

  menu :project_menu, :risks, { :controller => 'risks', :action => 'index' }, :caption => :label_risks, :before => :settings, :param => :project_id
  menu :project_menu, :new_risk, { :controller => 'risks', :action => 'new' }, :caption => :label_new_risk, :after => :new_wiki_sub, :param => :project_id, :parent => :new_object
  menu :project_menu, :risk_dashboard, { :controller => 'risk_dashboard', :action => 'project' }, :caption => :label_risk_dashboard, :after => :risks, :param => :project_id

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
  end

  # Pulls are added to the activity view
  activity_provider :risks, :class_name => ['Risk', 'Journal']
end

require File.dirname(__FILE__) + '/lib/redmine_risks'
