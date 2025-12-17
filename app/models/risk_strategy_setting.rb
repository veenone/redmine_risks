class RiskStrategySetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project

  validates :project_id, presence: true
  validates :key, presence: true, length: { maximum: 50 }
  validates :label, presence: true, length: { maximum: 255 }
  validates :key, uniqueness: { scope: :project_id, message: :taken }

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :key) }

  safe_attributes 'key', 'label', 'description', 'position', 'active'

  # Default strategy options
  DEFAULT_SETTINGS = [
    { key: 'accept', label: 'Accept', description: 'Accept the risk without taking action' },
    { key: 'mitigate', label: 'Mitigate', description: 'Take action to reduce probability or impact' },
    { key: 'transfer', label: 'Transfer', description: 'Transfer the risk to a third party' },
    { key: 'eliminate', label: 'Eliminate', description: 'Remove the risk entirely' }
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
