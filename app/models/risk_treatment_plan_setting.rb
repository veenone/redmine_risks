class RiskTreatmentPlanSetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  has_many :risk_treatment_plan_selections, dependent: :destroy
  has_many :risks, through: :risk_treatment_plan_selections

  validates :project_id, presence: true
  validates :key, presence: true, length: { maximum: 50 }
  validates :label, presence: true, length: { maximum: 255 }
  validates :key, uniqueness: { scope: :project_id, message: :taken }

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :key) }

  safe_attributes 'key', 'label', 'description', 'position', 'active'

  # Default treatment plan options
  DEFAULT_SETTINGS = [
    { key: 'mitigation', label: 'Mitigation', description: 'Actions to reduce the impact or probability after the risk occurs' },
    { key: 'prevention', label: 'Prevention', description: 'Actions to prevent the risk from occurring in the first place' },
    { key: 'acceptance', label: 'Acceptance', description: 'Accept the risk without specific treatment actions' },
    { key: 'transfer', label: 'Transfer', description: 'Transfer risk ownership to third party (insurance, contracts)' },
    { key: 'avoidance', label: 'Avoidance', description: 'Change plans to avoid the risk entirely' }
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

  # Get options for multi-select
  def self.options_for_project(project)
    for_project(project).map do |setting|
      [setting.label, setting.id]
    end
  end

  # Check if a setting can be deleted
  def deletable?
    risk_treatment_plan_selections.empty?
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
