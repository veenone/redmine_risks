class RiskCategoryEntry < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  has_many :risks, dependent: :nullify
  has_many :risk_registries, dependent: :nullify

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :project_id, case_sensitive: false }
  validates :code, length: { maximum: 10 }, allow_blank: true
  validates :code, uniqueness: { scope: :project_id, case_sensitive: false }, allow_blank: true
  validates :project, presence: true

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position, :name) }

  safe_attributes 'name', 'code', 'description', 'position', 'active'

  def to_s
    name
  end

  # Get the prefix character for Risk ID generation
  def risk_id_prefix
    code.present? ? code.first.upcase : name.first.upcase
  end
end
