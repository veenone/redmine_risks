class RiskActivityNote < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Redmine::I18n

  belongs_to :risk_activity
  belongs_to :author, :class_name => 'User'

  validates_presence_of :risk_activity, :content, :author

  scope :recent, -> { order(created_on: :desc) }

  before_create :set_created_on

  safe_attributes 'content'

  def visible?(user = User.current)
    risk_activity && risk_activity.visible?(user)
  end

  def editable?(user = User.current)
    user == author && risk_activity && risk_activity.editable?(user)
  end

  def deletable?(user = User.current)
    editable?(user)
  end

  def project
    risk_activity&.project
  end

  private

  def set_created_on
    self.created_on ||= Time.current
  end
end
