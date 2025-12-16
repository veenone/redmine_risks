class RiskImpactPointSetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project

  validates :project_id, presence: true
  validates :score, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :label, presence: true, length: { maximum: 255 }
  validates :score, uniqueness: { scope: :project_id, message: :taken }

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :score) }

  safe_attributes 'score', 'label', 'description', 'position', 'active'

  # Default impact point configuration (used when project has no custom settings)
  DEFAULT_SETTINGS = [
    { score: 1, label: 'Low', description: 'Limited productivity loss, limited delay in delivery.' },
    { score: 2, label: 'Significant', description: 'General productivity loss, SLA breach, local impact.' },
    { score: 3, label: 'Critical', description: 'Downgraded operational capability, significant impact on SLA, company image is altered, data breach requiring their replacement.' },
    { score: 4, label: 'Catastrophic', description: 'Very significant loss of operational capability (production stopped), data breach generating significant financial loss, impacting directly customers.' }
  ].freeze

  # Get settings for a project, or default settings if none configured
  def self.for_project(project)
    settings = where(project: project).active.sorted
    settings.any? ? settings : default_settings_for_project(project)
  end

  # Create default settings for a project
  def self.create_defaults_for_project(project)
    return if where(project: project).exists?

    DEFAULT_SETTINGS.each_with_index do |config, index|
      create!(
        project: project,
        score: config[:score],
        label: config[:label],
        description: config[:description],
        position: index + 1,
        active: true
      )
    end
  end

  # Get options for select dropdown
  def self.options_for_project(project)
    for_project(project).map do |setting|
      label_with_score = "#{setting.label} (#{setting.score})"
      [label_with_score, setting.score]
    end
  end

  # Get label for a specific score
  def self.label_for_score(project, score)
    return nil unless score
    setting = for_project(project).find { |s| s.score == score }
    setting ? "#{setting.label} (#{score})" : nil
  end

  # Get description for a specific score
  def self.description_for_score(project, score)
    return nil unless score
    setting = for_project(project).find { |s| s.score == score }
    setting&.description
  end

  private

  # Returns default settings as objects (for projects without custom settings)
  def self.default_settings_for_project(project)
    DEFAULT_SETTINGS.map.with_index do |config, index|
      new(
        project: project,
        score: config[:score],
        label: config[:label],
        description: config[:description],
        position: index + 1,
        active: true
      )
    end
  end
end
