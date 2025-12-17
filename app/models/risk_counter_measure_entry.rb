class RiskCounterMeasureEntry < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  has_many :risk_counter_measures

  validates :project_id, presence: true
  validates :name, presence: true, length: { maximum: 255 }

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :name) }

  safe_attributes 'name', 'description', 'position', 'active'

  # Get entries for a project
  def self.for_project(project)
    where(project: project).active.sorted
  end

  # Get options for select dropdown
  def self.options_for_project(project)
    for_project(project).map do |entry|
      [entry.name, entry.id]
    end
  end

  # Check if entry can be deleted
  def deletable?
    risk_counter_measures.empty?
  end

  # Get usage count
  def usage_count
    risk_counter_measures.count
  end
end
