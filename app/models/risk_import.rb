require 'csv'

class RiskImport
  include ActiveModel::Model

  attr_accessor :project, :user, :imported_count, :errors_list

  def initialize(attributes = {})
    super
    @imported_count = 0
    @errors_list = []
  end

  def errors
    @errors_list
  end

  def parse_file(file)
    content = file.read.force_encoding('UTF-8')
    # Handle BOM if present
    content = content.sub("\xEF\xBB\xBF", '')

    # Try to detect and handle different line endings
    content = content.gsub(/\r\n?/, "\n")

    csv = CSV.parse(content, headers: true, skip_blanks: true, liberal_parsing: true)

    # Find header row (skip rows until we find the data headers)
    header_mapping = detect_headers(csv.headers)

    csv.each_with_index do |row, index|
      next if row_empty?(row)
      next if header_row?(row)

      begin
        import_row(row, header_mapping, index + 2) # +2 for 1-based index and header row
      rescue => e
        @errors_list << "Row #{index + 2}: #{e.message}"
      end
    end
  end

  private

  def detect_headers(headers)
    mapping = {}
    headers.each_with_index do |header, index|
      next if header.nil?
      normalized = header.to_s.strip.downcase.gsub(/[\/\s]+/, '_').gsub(/[^a-z0-9_]/, '')

      case normalized
      when 'no', 'no_'
        mapping[:row_number] = index
      when 'category'
        mapping[:category] = index
      when 'risk'
        mapping[:subject] = index
      when 'threat_event'
        mapping[:threat_event] = index
      when 'risk_id'
        mapping[:risk_id] = index
      when 'areas_assets', 'areasassets'
        mapping[:areas_assets] = index
      when 'risk_owner'
        mapping[:risk_owner] = index
      when 'impacted_assets'
        mapping[:impacted_assets] = index
      when 'vulnerabilities'
        mapping[:vulnerabilities] = index
      when 'consequences'
        mapping[:consequences] = index
      when 'counter_measures', 'countermeasures'
        mapping[:counter_measures] = index
      when 'c'
        mapping[:confidentiality] = index
      when 'i'
        mapping[:integrity] = index
      when 'a'
        mapping[:availability] = index
      when 'impact'
        mapping[:impact_point] = index
      when 'probability'
        mapping[:probability_point] = index
      when 'level_of_significance'
        mapping[:level_of_significance] = index
      when 'risk_treatment'
        mapping[:risk_treatment_plan] = index
      when 'risk_treatment_owner'
        mapping[:risk_treatment_owner] = index
      when 'mitigation'
        mapping[:mitigation] = index
      when 'prevention'
        mapping[:prevention] = index
      when 'target_date'
        mapping[:target_date] = index
      when 'completion_date'
        mapping[:completion_date] = index
      when 'remark', 'remarks'
        mapping[:remark] = index
      end
    end
    mapping
  end

  def row_empty?(row)
    row.to_h.values.all? { |v| v.nil? || v.to_s.strip.empty? }
  end

  def header_row?(row)
    # Check if this looks like a sub-header row (contains only header-like values)
    values = row.to_h.values.compact.map(&:to_s).map(&:strip).reject(&:empty?)
    return true if values.empty?

    # Check if row contains typical sub-header values
    header_indicators = ['C', 'I', 'A', 'Impact', 'Probability', 'Mitigation', 'Prevention']
    matching = values.count { |v| header_indicators.include?(v) }
    matching >= 3
  end

  def import_row(row, mapping, row_number)
    values = row.to_h.values

    # Skip if no subject/risk name
    subject = get_value(values, mapping[:subject]) || get_value(values, mapping[:threat_event])
    return if subject.blank?

    # Build risk attributes
    risk = Risk.new(
      project: @project,
      author: @user,
      subject: subject,
      status: 'open'
    )

    # Set description from threat event if different from subject
    threat_event = get_value(values, mapping[:threat_event])
    if threat_event.present? && threat_event != subject
      risk.description = threat_event
    end

    # Category
    category_name = get_value(values, mapping[:category])
    if category_name.present?
      category = RiskCategory.find_or_create_by(name: category_name)
      risk.category = category
    end

    # Risk Owner
    risk_owner_name = get_value(values, mapping[:risk_owner])
    if risk_owner_name.present?
      risk_owner = find_user_by_name(risk_owner_name)
      risk.risk_owner = risk_owner if risk_owner
    end

    # Risk Treatment Owner
    treatment_owner_name = get_value(values, mapping[:risk_treatment_owner])
    if treatment_owner_name.present?
      treatment_owner = find_user_by_name(treatment_owner_name)
      risk.risk_treatment_owner = treatment_owner if treatment_owner
    end

    # Text fields
    risk.impacted_assets = get_value(values, mapping[:impacted_assets])
    risk.vulnerabilities = get_value(values, mapping[:vulnerabilities])
    risk.consequences = get_value(values, mapping[:consequences])
    risk.counter_measures = get_value(values, mapping[:counter_measures])

    # CIA Assessment (Y/N or numeric)
    risk.confidentiality = parse_cia_value(get_value(values, mapping[:confidentiality]))
    risk.integrity = parse_cia_value(get_value(values, mapping[:integrity]))
    risk.availability = parse_cia_value(get_value(values, mapping[:availability]))

    # Impact and Probability points
    impact = get_value(values, mapping[:impact_point])
    risk.impact_point = parse_numeric(impact) if impact.present?

    probability = get_value(values, mapping[:probability_point])
    risk.probability_point = parse_numeric(probability) if probability.present?

    # Risk Treatment Plan
    treatment_plan = get_value(values, mapping[:risk_treatment_plan])
    if treatment_plan.present?
      normalized_plan = treatment_plan.to_s.downcase.strip
      if normalized_plan.include?('transfer') || normalized_plan.include?('modif')
        risk.risk_treatment_plan = 'mitigation'
      elsif normalized_plan.include?('prevent')
        risk.risk_treatment_plan = 'prevention'
      elsif normalized_plan.include?('mitigat')
        risk.risk_treatment_plan = 'mitigation'
      end
    end

    # Build risk treatment from mitigation and prevention
    mitigation = get_value(values, mapping[:mitigation])
    prevention = get_value(values, mapping[:prevention])
    treatment_parts = []
    treatment_parts << "Mitigation:\n#{mitigation}" if mitigation.present?
    treatment_parts << "Prevention:\n#{prevention}" if prevention.present?
    risk.risk_treatment = treatment_parts.join("\n\n") if treatment_parts.any?

    # Lessons/Remark
    remark = get_value(values, mapping[:remark])
    risk.lessons = remark if remark.present?

    if risk.save
      @imported_count += 1
    else
      @errors_list << "Row #{row_number}: #{risk.errors.full_messages.join(', ')}"
    end
  end

  def get_value(values, index)
    return nil if index.nil? || values[index].nil?
    value = values[index].to_s.strip
    value.empty? ? nil : value
  end

  def parse_cia_value(value)
    return nil if value.blank?
    normalized = value.to_s.strip.upcase
    case normalized
    when 'Y', 'YES', '1', 'TRUE', 'HIGH'
      1  # Yes/High
    when 'N', 'NO', '0', 'FALSE', 'LOW'
      0  # No/Low
    when 'M', 'MEDIUM'
      1  # Medium -> map to index 1
    else
      nil
    end
  end

  def parse_numeric(value)
    return nil if value.blank?
    # Extract first number from string like "3" or "Critical" -> look for number
    if value =~ /(\d+)/
      $1.to_i
    else
      # Try to map text values
      case value.to_s.downcase.strip
      when 'very low' then 1
      when 'low' then 2
      when 'medium' then 3
      when 'high' then 4
      when 'catastrophic', 'critical' then 3
      when 'significant' then 2
      else nil
      end
    end
  end

  def find_user_by_name(name)
    return nil if name.blank?
    # Try to find user by login, firstname, lastname, or full name
    User.active.where("login LIKE ? OR firstname LIKE ? OR lastname LIKE ? OR CONCAT(firstname, ' ', lastname) LIKE ?",
                      "%#{name}%", "%#{name}%", "%#{name}%", "%#{name}%").first
  end
end
