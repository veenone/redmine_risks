class RiskArea < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  has_many :risks, dependent: :nullify

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :project, presence: true

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :name) }

  safe_attributes 'name', 'description', 'position', 'active'

  def to_s
    name
  end
end
