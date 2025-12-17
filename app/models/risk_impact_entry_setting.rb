class RiskImpactEntrySetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project

  validates :project_id, presence: true
  validates :key, presence: true, length: { maximum: 50 }
  validates :label, presence: true, length: { maximum: 255 }
  validates :key, uniqueness: { scope: :project_id, message: :taken }

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :key) }

  safe_attributes 'key', 'label', 'description', 'position', 'active'

  # Default impact level options (different from impact points)
  DEFAULT_SETTINGS = [
    { key: 'negligible', label: 'Negligible', description: 'Minimal impact on operations' },
    { key: 'minor', label: 'Minor', description: 'Limited impact on operations' },
    { key: 'moderate', label: 'Moderate', description: 'Moderate impact on operations' },
    { key: 'significant', label: 'Significant', description: 'Significant impact on operations' },
    { key: 'severe', label: 'Severe', description: 'Severe impact, major disruption' }
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
        key: config[:key],
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
      [setting.label, setting.key]
    end
  end

  # Get label for a specific key
  def self.label_for_key(project, key)
    return nil unless key
    setting = for_project(project).find { |s| s.key == key }
    setting&.label
  end

  private

  def self.default_settings_for_project(project)
    DEFAULT_SETTINGS.map.with_index do |config, index|
      new(
        project: project,
        key: config[:key],
        label: config[:label],
        description: config[:description],
        position: index + 1,
        active: true
      )
    end
  end
end
