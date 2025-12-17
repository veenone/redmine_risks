class RiskReportsController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  helper :risks
  helper :queries
  include RisksHelper
  include QueriesHelper

  def index
    # Report menu/index page
  end

  # Risk list report with customizable query
  def risk_list
    retrieve_query(RiskQuery)
    @query.project = @project

    if @query.valid?
      @limit = Setting.issues_export_limit.to_i
      @risk_count = @query.risk_count
      @risks = @query.risks(limit: @limit)

      # Load additional data for display
      Risk.load_visible_last_updated_by(@risks) if @query.has_column?(:last_updated_by)
      Risk.load_visible_last_notes(@risks) if @query.has_column?(:last_notes)
    end

    respond_to do |format|
      format.html
      format.csv { send_data query_to_csv(@risks, @query), type: 'text/csv; header=present', filename: "risks_report_#{Date.today}.csv" }
      format.pdf { render_risk_list_pdf }
    end
  end

  # Dashboard-based report
  def dashboard
    project_risks = @project.respond_to?(:risks) ? @project.risks : Risk.where(project_id: @project.id)

    # Statistics
    @total_risks = project_risks.count
    @open_risks = project_risks.where(closed_on: nil).count
    @closed_risks = project_risks.where.not(closed_on: nil).count

    # Registry data
    @total_categories = @project.risk_category_entries.count rescue 0
    @total_registries = @project.risk_registries.count rescue 0
    @total_areas = @project.risk_areas.count rescue 0

    # Risks by category
    @risks_by_category = project_risks.joins(:risk_category_entry)
                                      .group('risk_category_entries.name')
                                      .count rescue {}

    # Risks by treatment plan
    @risks_by_treatment_plan = project_risks.group(:risk_treatment_plan).count.reject { |k, _| k.nil? || k.blank? }

    # Risks by status
    @risks_by_status = project_risks.group(:status).count

    # Risks by strategy
    @risks_by_strategy = project_risks.group(:strategy).count.reject { |k, _| k.nil? }

    # CIA distribution
    @risks_by_confidentiality = project_risks.group(:confidentiality).count
    @risks_by_integrity = project_risks.group(:integrity).count
    @risks_by_availability = project_risks.group(:availability).count

    # Risk significance data
    @avg_significance = project_risks.where.not(level_of_significance: nil).average(:level_of_significance)
    @max_significance = project_risks.maximum(:level_of_significance)

    # Significance distribution
    @significance_distribution = project_risks.where.not(level_of_significance: nil)
                                              .group(:level_of_significance)
                                              .count
                                              .sort_by { |k, _| k }

    # Top risks by significance
    @top_risks_by_significance = project_risks.where(closed_on: nil)
                                             .where.not(level_of_significance: nil)
                                             .order(level_of_significance: :desc)
                                             .limit(10)

    # Risks by owner
    @risks_by_owner = project_risks.joins("LEFT OUTER JOIN users ON users.id = risks.risk_owner_id")
                                   .group("COALESCE(users.firstname || ' ' || users.lastname, 'Unassigned')")
                                   .count

    # Impact/Probability matrix data
    @impact_point_settings = RiskImpactPointSetting.for_project(@project)
    @probability_point_settings = RiskProbabilityPointSetting.for_project(@project)
    @impact_probability_matrix = build_impact_probability_matrix(project_risks)

    respond_to do |format|
      format.html
      format.pdf { render_dashboard_pdf }
    end
  end

  # Risk registry report
  def registry
    @categories = @project.risk_category_entries.active.sorted rescue []
    @registries = @project.risk_registries.active.sorted rescue []
    @areas = @project.risk_areas.active.sorted rescue []

    # Build registry data
    @registry_data = build_registry_data

    respond_to do |format|
      format.html
      format.csv { send_data registry_to_csv, type: 'text/csv; header=present', filename: "risk_registry_#{Date.today}.csv" }
      format.pdf { render_registry_pdf }
    end
  end

  private

  def build_impact_probability_matrix(risks)
    matrix = {}
    impact_settings = RiskImpactPointSetting.for_project(@project)
    probability_settings = RiskProbabilityPointSetting.for_project(@project)

    probability_settings.each do |prob|
      matrix[prob.score] = {}
      impact_settings.each do |imp|
        count = risks.where(probability_point: prob.score, impact_point: imp.score).count
        matrix[prob.score][imp.score] = count
      end
    end

    matrix
  end

  def build_registry_data
    project_risks = @project.respond_to?(:risks) ? @project.risks : Risk.where(project_id: @project.id)

    data = {
      by_category: {},
      by_registry: {},
      by_area: {},
      unassigned: []
    }

    # Group by category
    @categories.each do |cat|
      data[:by_category][cat.id] = {
        name: cat.name,
        code: cat.code,
        risks: project_risks.where(risk_category_entry_id: cat.id).includes(:risk_owner, :risk_treatment_owner)
      }
    end

    # Group by registry
    @registries.each do |reg|
      data[:by_registry][reg.id] = {
        name: reg.name,
        risks: project_risks.where(risk_registry_id: reg.id).includes(:risk_owner, :risk_treatment_owner)
      }
    end

    # Group by area
    @areas.each do |area|
      data[:by_area][area.id] = {
        name: area.name,
        risks: project_risks.where(risk_area_id: area.id).includes(:risk_owner, :risk_treatment_owner)
      }
    end

    # Unassigned risks
    data[:unassigned] = project_risks.where(risk_category_entry_id: nil, risk_registry_id: nil, risk_area_id: nil)
                                     .includes(:risk_owner, :risk_treatment_owner)

    data
  end

  def query_to_csv(risks, query)
    require 'csv'

    columns = query.columns

    CSV.generate(col_sep: ',', encoding: 'UTF-8') do |csv|
      # Header row
      csv << columns.map { |c| c.caption.to_s }

      # Data rows
      risks.each do |risk|
        csv << columns.map { |c| csv_value_for(risk, c) }
      end
    end
  end

  def csv_value_for(risk, column)
    value = column.value(risk)
    case value
    when Date
      value.strftime('%Y-%m-%d')
    when Time
      value.strftime('%Y-%m-%d %H:%M')
    when TrueClass
      'Yes'
    when FalseClass
      'No'
    when User, Group
      value.name
    when Array
      value.map(&:to_s).join(', ')
    else
      value.to_s
    end
  end

  def registry_to_csv
    require 'csv'

    project_risks = @project.respond_to?(:risks) ? @project.risks : Risk.where(project_id: @project.id)
    risks = project_risks.includes(:risk_category_entry, :risk_registry, :risk_area, :risk_owner, :risk_treatment_owner)

    CSV.generate(col_sep: ',', encoding: 'UTF-8') do |csv|
      # Header
      csv << [
        l(:field_risk_id_code),
        l(:field_risk_category_entry),
        l(:field_risk_registry),
        l(:field_risk_area),
        l(:field_subject),
        l(:field_risk_owner_id),
        l(:field_status),
        l(:field_impact_point),
        l(:field_probability_point),
        l(:field_level_of_significance),
        l(:field_risk_treatment_plan),
        l(:field_risk_treatment_owner_id)
      ]

      # Data
      risks.each do |risk|
        csv << [
          risk.risk_id_code,
          risk.risk_category_entry&.name,
          risk.risk_registry&.name,
          risk.risk_area&.name,
          risk.subject,
          risk.risk_owner&.name,
          risk.status,
          risk.impact_point,
          risk.probability_point,
          risk.level_of_significance,
          risk.risk_treatment_plan,
          risk.risk_treatment_owner&.name
        ]
      end
    end
  end

  def render_risk_list_pdf
    send_data(
      risk_list_to_pdf(@risks, @query),
      type: 'application/pdf',
      filename: "risks_report_#{Date.today}.pdf",
      disposition: 'attachment'
    )
  end

  def render_dashboard_pdf
    send_data(
      dashboard_to_pdf,
      type: 'application/pdf',
      filename: "risk_dashboard_report_#{Date.today}.pdf",
      disposition: 'attachment'
    )
  end

  def render_registry_pdf
    send_data(
      registry_to_pdf,
      type: 'application/pdf',
      filename: "risk_registry_report_#{Date.today}.pdf",
      disposition: 'attachment'
    )
  end

  def risk_list_to_pdf(risks, query)
    pdf = Redmine::Export::PDF::ITCPDF.new(current_language)
    pdf.set_title("#{l(:label_risk_list_report)} - #{@project.name}")
    pdf.alias_nb_pages
    pdf.footer_date = format_date(User.current.today)
    pdf.add_page("L")

    # Get PDF settings
    pdf_settings = RiskProjectSetting.for_project(@project)

    # Render PDF header with logo, metadata, product name
    render_pdf_header(pdf, pdf_settings, l(:label_risk_list_report))

    # Column headers
    pdf.SetFontStyle('B', 8)
    col_widths = calculate_col_widths_smart(query.columns)
    row_height = 6

    query.columns.each_with_index do |col, i|
      pdf.RDMCell(col_widths[i], row_height, col.caption.to_s, 1, 0, 'C')
    end
    pdf.ln

    # Data rows
    pdf.SetFontStyle('', 8)
    base_row_height = 5
    left_margin = pdf.get_x  # Store initial left margin position

    risks.each do |risk|
      # Prepare cell values and calculate required heights
      cell_values = query.columns.map { |col| format_pdf_cell_value(csv_value_for(risk, col), col) }

      # Calculate the maximum row height needed
      max_row_height = base_row_height
      cell_values.each_with_index do |value, i|
        cell_height = calculate_cell_height(pdf, value, col_widths[i], base_row_height)
        max_row_height = [max_row_height, cell_height].max
      end

      # Check if we need a new page
      if pdf.get_y + max_row_height > pdf.get_page_height - 15
        pdf.add_page("L")
        # Reprint headers on new page
        pdf.SetFontStyle('B', 8)
        query.columns.each_with_index do |col, i|
          pdf.RDMCell(col_widths[i], row_height, col.caption.to_s, 1, 0, 'C')
        end
        pdf.ln
        pdf.SetFontStyle('', 8)
      end

      # Record starting position
      start_x = pdf.get_x
      start_y = pdf.get_y

      # Render each cell with uniform height
      cell_values.each_with_index do |value, i|
        pdf.set_xy(start_x, start_y)
        render_pdf_table_cell(pdf, value, col_widths[i], max_row_height)
        start_x += col_widths[i]
      end

      # Move to next row
      pdf.set_xy(left_margin, start_y + max_row_height)
    end

    pdf.output
  end

  def dashboard_to_pdf
    pdf = Redmine::Export::PDF::ITCPDF.new(current_language)
    pdf.set_title("#{l(:label_risk_dashboard_report)} - #{@project.name}")
    pdf.alias_nb_pages
    pdf.footer_date = format_date(User.current.today)
    pdf.add_page("P")

    # Get PDF settings
    pdf_settings = RiskProjectSetting.for_project(@project)

    # Render PDF header with logo, metadata, product name
    render_pdf_header(pdf, pdf_settings, l(:label_risk_dashboard_report))

    # Summary statistics
    pdf.SetFontStyle('B', 10)
    pdf.RDMCell(0, 6, l(:label_risks_overview), 0, 1, 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, "#{l(:label_total_risks)}: #{@total_risks}", 0, 0, 'L')
    pdf.RDMCell(60, 5, "#{l(:label_open_risks)}: #{@open_risks}", 0, 0, 'L')
    pdf.RDMCell(60, 5, "#{l(:label_closed_risks)}: #{@closed_risks}", 0, 1, 'L')
    pdf.ln(4)

    # Significance
    pdf.SetFontStyle('B', 10)
    pdf.RDMCell(0, 6, l(:label_risk_significance), 0, 1, 'L')
    pdf.SetFontStyle('', 9)
    avg_sig = @avg_significance ? sprintf('%.2f', @avg_significance) : '-'
    pdf.RDMCell(60, 5, "#{l(:label_average_significance)}: #{avg_sig}", 0, 0, 'L')
    pdf.RDMCell(60, 5, "#{l(:label_max_significance)}: #{@max_significance || '-'}", 0, 1, 'L')
    pdf.ln(4)

    # Top risks
    if @top_risks_by_significance.any?
      pdf.SetFontStyle('B', 10)
      pdf.RDMCell(0, 6, l(:label_top_risks_by_significance), 0, 1, 'L')
      pdf.SetFontStyle('B', 8)
      pdf.RDMCell(20, 5, l(:label_risk_id), 1, 0, 'C')
      pdf.RDMCell(100, 5, l(:field_subject), 1, 0, 'C')
      pdf.RDMCell(30, 5, l(:field_level_of_significance), 1, 0, 'C')
      pdf.RDMCell(30, 5, l(:field_status), 1, 1, 'C')
      pdf.SetFontStyle('', 8)
      @top_risks_by_significance.each do |risk|
        pdf.RDMCell(20, 5, "##{risk.id}", 1, 0, 'L')
        pdf.RDMCell(100, 5, risk.subject.to_s.truncate(60), 1, 0, 'L')
        pdf.RDMCell(30, 5, risk.level_of_significance.to_s, 1, 0, 'C')
        pdf.RDMCell(30, 5, risk.status, 1, 1, 'C')
      end
    end

    pdf.ln(4)

    # Risks by status
    pdf.SetFontStyle('B', 10)
    pdf.RDMCell(0, 6, l(:label_risks_by_status), 0, 1, 'L')
    pdf.SetFontStyle('', 9)
    @risks_by_status.each do |status, count|
      pdf.RDMCell(0, 5, "#{format_risk_status(status)}: #{count}", 0, 1, 'L')
    end

    pdf.output
  end

  def registry_to_pdf
    pdf = Redmine::Export::PDF::ITCPDF.new(current_language)
    pdf.set_title("#{l(:label_risk_registry_report)} - #{@project.name}")
    pdf.alias_nb_pages
    pdf.footer_date = format_date(User.current.today)
    pdf.add_page("L")

    # Get PDF settings
    pdf_settings = RiskProjectSetting.for_project(@project)

    # Render PDF header with logo, metadata, product name
    render_pdf_header(pdf, pdf_settings, l(:label_risk_registry_report))

    # Registry summary
    pdf.SetFontStyle('B', 10)
    pdf.RDMCell(0, 6, l(:label_registry_overview), 0, 1, 'L')
    pdf.SetFontStyle('', 9)
    pdf.RDMCell(60, 5, "#{l(:label_risk_category_entries)}: #{@categories.count}", 0, 0, 'L')
    pdf.RDMCell(60, 5, "#{l(:label_risk_registries)}: #{@registries.count}", 0, 0, 'L')
    pdf.RDMCell(60, 5, "#{l(:label_risk_areas)}: #{@areas.count}", 0, 1, 'L')
    pdf.ln(4)

    # Risks by category
    @registry_data[:by_category].each do |_id, cat_data|
      next if cat_data[:risks].empty?

      pdf.SetFontStyle('B', 10)
      pdf.RDMCell(0, 6, "#{l(:field_risk_category_entry)}: #{cat_data[:name]}", 0, 1, 'L')

      # Table header
      pdf.SetFontStyle('B', 8)
      pdf.RDMCell(15, 5, 'ID', 1, 0, 'C')
      pdf.RDMCell(80, 5, l(:field_subject), 1, 0, 'C')
      pdf.RDMCell(40, 5, l(:field_risk_owner_id), 1, 0, 'C')
      pdf.RDMCell(20, 5, l(:field_impact_point), 1, 0, 'C')
      pdf.RDMCell(20, 5, l(:field_probability_point), 1, 0, 'C')
      pdf.RDMCell(25, 5, l(:field_level_of_significance), 1, 0, 'C')
      pdf.RDMCell(25, 5, l(:field_status), 1, 1, 'C')

      pdf.SetFontStyle('', 8)
      cat_data[:risks].each do |risk|
        pdf.RDMCell(15, 5, "##{risk.id}", 1, 0, 'L')
        pdf.RDMCell(80, 5, risk.subject.to_s.truncate(50), 1, 0, 'L')
        pdf.RDMCell(40, 5, risk.risk_owner&.name.to_s.truncate(25), 1, 0, 'L')
        pdf.RDMCell(20, 5, risk.impact_point.to_s, 1, 0, 'C')
        pdf.RDMCell(20, 5, risk.probability_point.to_s, 1, 0, 'C')
        pdf.RDMCell(25, 5, risk.level_of_significance.to_s, 1, 0, 'C')
        pdf.RDMCell(25, 5, risk.status.to_s, 1, 1, 'C')
      end
      pdf.ln(4)
    end

    pdf.output
  end

  def calculate_col_widths(columns)
    # Calculate proportional widths based on column count
    total_width = 277 # A4 landscape minus margins
    base_width = total_width / columns.size
    columns.map { base_width }
  end

  # Smart column width calculation based on column type
  def calculate_col_widths_smart(columns)
    total_width = 277 # A4 landscape minus margins

    # Define preferred widths for known column types
    width_hints = {
      id: 15,
      risk_id_code: 25,
      subject: 80,
      description: 60,
      status: 20,
      probability: 25,
      impact: 25,
      probability_point: 20,
      impact_point: 20,
      level_of_significance: 25,
      risk_owner: 35,
      risk_treatment_owner: 35,
      risk_treatment_plan: 30,
      created_on: 25,
      updated_on: 25,
      closed_on: 25,
      risk_category_entry: 35,
      risk_registry: 35,
      risk_area: 35,
      confidentiality: 25,
      integrity: 25,
      availability: 25
    }

    # Calculate initial widths
    widths = columns.map do |col|
      width_hints[col.name] || 30 # Default width
    end

    # Scale to fit total width
    total_assigned = widths.sum
    if total_assigned != total_width
      scale_factor = total_width.to_f / total_assigned
      widths = widths.map { |w| (w * scale_factor).round }
    end

    # Adjust for rounding errors
    diff = total_width - widths.sum
    widths[-1] += diff if widths.any?

    widths
  end

  # Format cell value for PDF display
  def format_pdf_cell_value(value, column)
    return '' if value.nil?
    text = value.to_s.strip
    # Remove newlines and excess whitespace
    text.gsub(/[\r\n]+/, ' ').gsub(/\s+/, ' ')
  end

  # Calculate the height needed for a cell based on text content
  def calculate_cell_height(pdf, text, width, line_height)
    return line_height if text.blank?

    # Get string width to estimate lines needed
    # ITCPDF uses approximately 2.2 points per character at font size 8
    text_width = pdf.get_string_width(text)
    usable_width = width - 2 # Account for cell padding

    if text_width <= usable_width
      line_height
    else
      # Calculate number of lines needed
      lines = (text_width / usable_width).ceil
      lines = [lines, 5].min # Cap at 5 lines maximum
      lines * line_height
    end
  end

  # Render a table cell with text wrapping and border
  def render_pdf_table_cell(pdf, text, width, height)
    x = pdf.get_x
    y = pdf.get_y

    # Draw cell border
    pdf.Rect(x, y, width, height)

    # Add text with padding
    if text.present?
      pdf.set_xy(x + 1, y + 1)
      # Truncate text to fit if too long, with word boundary awareness
      max_chars = estimate_max_chars(width - 2, height, 4)
      display_text = smart_truncate(text, max_chars)
      pdf.RDMMultiCell(width - 2, 4, display_text, 0, 'L')
    end

    # Reset position for next cell
    pdf.set_xy(x + width, y)
  end

  # Estimate maximum characters that fit in a cell
  def estimate_max_chars(width, height, line_height)
    chars_per_line = (width / 2.0).to_i  # ~2 points per char at font size 8
    lines = (height / line_height).to_i
    chars_per_line * lines
  end

  # Smart truncate text at word boundaries
  def smart_truncate(text, max_chars)
    return text if text.length <= max_chars
    truncated = text[0, max_chars]
    # Try to break at last space
    last_space = truncated.rindex(' ')
    if last_space && last_space > max_chars * 0.5
      truncated = truncated[0, last_space]
    end
    truncated.strip + '...'
  end

  # Render PDF header with logo, metadata, and product name
  def render_pdf_header(pdf, settings, report_title)
    header_height = 0
    start_y = pdf.get_y

    # Logo (left side)
    if settings&.pdf_logo_exists?
      begin
        logo_path = settings.pdf_logo_file_path
        pdf.image(logo_path, pdf.get_x, start_y, 30, 0, '', '', '', false, 300)
        header_height = [header_height, 15].max
      rescue => e
        Rails.logger.warn "Failed to load PDF logo: #{e.message}"
      end
    end

    # Title and metadata (center/right)
    text_x = settings&.pdf_logo_exists? ? 45 : pdf.get_x
    pdf.set_xy(text_x, start_y)

    # Product name (if enabled)
    if settings&.pdf_show_product_name? && settings.pdf_product_name.present?
      pdf.SetFontStyle('B', 10)
      pdf.RDMCell(0, 5, settings.pdf_product_name, 0, 1, 'L')
      pdf.set_x(text_x)
      header_height = [header_height, 5].max
    end

    # Report title
    pdf.SetFontStyle('B', 12)
    pdf.RDMCell(0, 6, "#{report_title} - #{@project.name}", 0, 1, 'L')
    pdf.set_x(text_x)
    header_height = [header_height, 11].max

    # Generated time (if enabled)
    if settings&.pdf_show_generated_time?
      pdf.SetFontStyle('', 9)
      pdf.RDMCell(0, 5, "#{l(:label_generated_on)}: #{format_time(Time.now)}", 0, 1, 'L')
      header_height += 5
    end

    # Project info
    pdf.SetFontStyle('', 9)
    pdf.set_x(text_x)
    pdf.RDMCell(0, 5, "#{l(:field_project)}: #{@project.name}", 0, 1, 'L')

    # Add spacing after header
    pdf.ln(6)
  end
end
