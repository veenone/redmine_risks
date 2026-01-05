require 'redmine'

RISKS_VERSION_NUMBER = '2.3.1'

Redmine::Plugin.register :redmine_risks do
  name 'Risks'
  author 'Mun Mun Das'
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
  menu :project_menu, :risk_categories, { :controller => 'risk_category_entries', :action => 'index' }, :caption => :label_risk_category_entries, :param => :project_id, :parent => :risk_management, :if => Proc.new { |p| User.current.allowed_to?(:manage_risk_registries, p) }
  menu :project_menu, :risk_registries, { :controller => 'risk_registries', :action => 'index' }, :caption => :label_risk_registries, :param => :project_id, :parent => :risk_management, :if => Proc.new { |p| User.current.allowed_to?(:manage_risk_registries, p) }
  menu :project_menu, :risk_areas, { :controller => 'risk_areas', :action => 'index' }, :caption => :label_risk_areas, :param => :project_id, :parent => :risk_management, :if => Proc.new { |p| User.current.allowed_to?(:manage_risk_registries, p) }
  menu :project_menu, :risk_settings, { :controller => 'risk_project_settings', :action => 'show' }, :caption => :label_risk_settings, :param => :project_id, :parent => :risk_management, :if => Proc.new { |p| User.current.allowed_to?(:manage_risk_settings, p) }
  menu :project_menu, :risk_reports, { :controller => 'risk_reports', :action => 'index' }, :caption => :label_risk_reports, :param => :project_id, :parent => :risk_management, :if => Proc.new { |p| User.current.allowed_to?(:view_risk_reports, p) }

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

    # Risk settings (includes point settings management)
    permission :manage_risk_settings, {
      :risk_project_settings => [:show, :update, :initialize_point_settings,
                                  :update_impact_points, :update_probability_points,
                                  :add_impact_point, :add_probability_point,
                                  :delete_impact_point, :delete_probability_point,
                                  :delete_logo,
                                  :initialize_strategy_settings, :update_strategy_settings,
                                  :add_strategy_setting, :delete_strategy_setting,
                                  :initialize_probability_entry_settings, :update_probability_entry_settings,
                                  :add_probability_entry_setting, :delete_probability_entry_setting,
                                  :initialize_impact_entry_settings, :update_impact_entry_settings,
                                  :add_impact_entry_setting, :delete_impact_entry_setting,
                                  :initialize_treatment_plan_settings, :update_treatment_plan_settings,
                                  :add_treatment_plan_setting, :delete_treatment_plan_setting,
                                  :add_vulnerability_entry, :delete_vulnerability_entry,
                                  :add_consequence_entry, :delete_consequence_entry,
                                  :add_counter_measure_entry, :delete_counter_measure_entry]
    }

    # Risk import
    permission :import_risks, { :risk_imports => [:new, :create, :template] }

    # Risk registries management
    permission :manage_risk_registries, {
      :risk_category_entries => [:index, :new, :create, :edit, :update, :destroy],
      :risk_registries => [:index, :new, :create, :edit, :update, :destroy],
      :risk_areas => [:index, :new, :create, :edit, :update, :destroy]
    }

    # Risk reports
    permission :view_risk_reports, {
      :risk_reports => [:index, :risk_list, :dashboard, :registry]
    }, :read => true
  end

  # Pulls are added to the activity view
  activity_provider :risks, :class_name => ['Risk', 'Journal']
end

require File.dirname(__FILE__) + '/lib/redmine_risks'
