class RiskRegistry < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :risk_category_entry, optional: true
  has_many :risks, dependent: :nullify

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :project, presence: true

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :name) }
  scope :by_category, ->(category_id) { where(risk_category_entry_id: category_id) if category_id.present? }

  safe_attributes 'name', 'risk_category_entry_id', 'description', 'position', 'active'

  def to_s
    name
  end

  def category
    risk_category_entry
  end
end
