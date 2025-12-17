class RiskCounterMeasure < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :risk
  belongs_to :risk_counter_measure_entry, optional: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :risk, presence: true

  scope :sorted, -> { order(:position, :name) }

  safe_attributes 'name', 'description', 'position', 'risk_counter_measure_entry_id'

  # After save callback to create project-level entry if it doesn't exist
  after_save :ensure_project_entry

  def to_s
    name
  end

  private

  def ensure_project_entry
    return if risk_counter_measure_entry_id.present?
    return if name.blank?

    project = risk&.project
    return unless project

    # Find or create project-level entry
    entry = RiskCounterMeasureEntry.find_or_create_by(project: project, name: name) do |e|
      e.description = description
      e.active = true
    end
    update_column(:risk_counter_measure_entry_id, entry.id) if entry.persisted?
  end
end
