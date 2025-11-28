module RisksHelper
  include IssuesHelper
  include QueriesHelper

  def find_risk
    risk_id = params[:risk_id] || params[:id]

    @risk = Risk.find(risk_id)
    raise Unauthorized unless @risk.visible?
    @project = @risk.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_risks
    @risks = Risk
      .where(:id => (params[:id] || params[:ids]))
      .preload(:project, :author, :assigned_to)
      .to_a

    raise ActiveRecord::RecordNotFound if @risks.empty?
    raise Unauthorized unless @risks.all?(&:visible?)

    @projects = @risks.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def format_risk_status(status)
    if status.present?
      l("label_risk_status_#{status}")
    else
      l(:label_risk_status_unknown)
    end
  end

  def format_risk_probability(probability)
    format_risk_level(Risk::RISK_PROBABILITY, probability) {|p| l("label_risk_probability_#{p}")}
  end

  def format_risk_impact(impact)
    format_risk_level(Risk::RISK_IMPACT, impact) {|i| l("label_risk_impact_#{i}")}
  end

  def format_risk_strategy(strategy)
    return unless Risk::RISK_STRATEGY.include?(strategy)
    l("label_risk_strategy_#{strategy}")
  end

  def format_risk_level(levels, level, &block)
    return if level.nil?

    increment = 100 / (levels.count - 1)

    if level % increment != 0
      return level.to_s + "%"
    end

    yield levels[level / increment]
  end

  def format_risk_levels(levels, value = nil, &block)
    index     = 0
    increment = 100 / (levels.count - 1)

    levels.collect do |level|
      value  = index * increment
      index += 1

      [yield(value), value]
    end
  end

  def render_risk_relations(risk)
    manage_relations = User.current.allowed_to?(:manage_risk_relations, risk.project)

    relations = risk.issues.visible.collect do |issue|
      delete_link = link_to(l(:label_relation_delete),
                            {:controller => 'risk_issues', :action => 'destroy', :risk_id => @risk, :issue_id => issue},
                            :remote => true,
                            :method => :delete,
                            :data => {:confirm => l(:text_are_you_sure)},
                            :title => l(:label_relation_delete),
                            :class => 'icon-only icon-link-break')

      relation = ''.html_safe

      relation << content_tag('td', check_box_tag("ids[]", issue.id, false, :id => nil), :class => 'checkbox')
      relation << content_tag('td', link_to_issue(issue, :project => Setting.cross_project_issue_relations?).html_safe, :class => 'subject', :style => 'width: 50%')
      relation << content_tag('td', issue.status, :class => 'status')
      relation << content_tag('td', issue.start_date, :class => 'start_date')
      relation << content_tag('td', issue.due_date, :class => 'due_date')
      relation << content_tag('td', progress_bar(issue.done_ratio), :class=> 'done_ratio') unless issue.disabled_core_fields.include?('done_ratio')
      relation << content_tag('td', delete_link, :class => 'buttons') if manage_relations

      content_tag('tr', relation, :id => "relation-#{issue.id}", :class => "issue hascontextmenu #{issue.css_classes}")
    end

    content_tag('table', relations.join.html_safe, :class => 'list issues odd-even')
  end

  def risk_details_to_strings(details, no_html=false, options={})
    # The plugin Redmine Checklists patch the method IssuesHelper::details_to_strings and suppose
    # that it's only used for issues. Thus, if the unpatched version exists, we'll use it instead.
    if respond_to?('details_to_strings_without_checklists')
      return details_to_strings_without_checklists(details, no_html, options)
    end

    details_to_strings(details, no_html, options)
  end

  def format_risk_confidentiality(level, project = nil)
    return unless level.present?
    format_cia_value(level, :confidentiality, project)
  end

  def format_risk_integrity(level, project = nil)
    return unless level.present?
    format_cia_value(level, :integrity, project)
  end

  def format_risk_availability(level, project = nil)
    return unless level.present?
    format_cia_value(level, :availability, project)
  end

  # Format CIA value based on project setting (levels vs boolean mode)
  def format_cia_value(level, field, project)
    return nil if level.nil?

    setting = project ? RiskProjectSetting.for_project(project) : nil

    if setting&.boolean_cia_mode?
      # Boolean mode: 0 = No, 1 = Yes
      bool_value = Risk::RISK_CIA_BOOLEAN[level.to_i]
      return nil unless bool_value
      l("label_risk_cia_#{bool_value}")
    else
      # Levels mode: 0 = low, 1 = medium, 2 = high
      levels = case field
               when :confidentiality then Risk::RISK_CONFIDENTIALITY
               when :integrity then Risk::RISK_INTEGRITY
               when :availability then Risk::RISK_AVAILABILITY
               end
      return nil unless levels && level.to_i < levels.length
      l("label_risk_#{field}_#{levels[level.to_i]}")
    end
  end

  def column_value_with_risks(column, item, value)
    case column.name
    when :id, :subject
      link_to value, risk_path(item)
    when :probability
      format_risk_probability(value)
    when :impact
      format_risk_impact(value)
    when :status
      format_risk_status(value)
    when :strategy
      format_risk_strategy(value)
    when :treatments
      item.treatments? ? content_tag('div', textilizable(item, :treatments), :class => "wiki") : ''
    when :lessons
      item.lessons? ? content_tag('div', textilizable(item, :lessons), :class => "wiki") : ''
    when :owner
      value ? link_to_user(value) : ''
    when :confidentiality
      format_risk_confidentiality(value, item.project)
    when :integrity
      format_risk_integrity(value, item.project)
    when :availability
      format_risk_availability(value, item.project)
    when :risk_owner
      item.risk_owner ? link_to_user(item.risk_owner) : ''
    when :action_owner
      item.action_owner ? link_to_user(item.action_owner) : ''
    when :probability_point
      value
    when :impact_point
      value
    when :level_of_significance
      value
    else
      column_value_without_risks(column, item, value)
    end
  end

  def status_color(status)
    case status.to_s
    when 'open'
      'rgba(54, 162, 235, 0.8)'  # Blue
    when 'closed'
      'rgba(75, 192, 192, 0.8)'  # Green
    when 'rejected'
      'rgba(255, 99, 132, 0.8)'  # Red
    else
      'rgba(201, 203, 207, 0.8)' # Grey
    end
  end

  def get_significance_class(value)
    return '' unless value.present?
    if value >= 12
      'critical'
    elsif value >= 8
      'high'
    elsif value >= 4
      'medium'
    else
      'low'
    end
  end
  
  alias_method :column_value_without_risks, :column_value
  alias_method :column_value, :column_value_with_risks
end
