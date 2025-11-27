class RiskActivity < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Redmine::I18n

  belongs_to :risk
  belongs_to :author, :class_name => 'User'
  belongs_to :assigned_to, :class_name => 'Principal'

  has_many :notes, :class_name => 'RiskActivityNote', :dependent => :destroy

  ACTIVITY_TYPES = %w(assessment mitigation monitoring review contingency)
  ACTIVITY_STATUSES = %w(planned in_progress completed cancelled)

  validates_presence_of :risk, :subject, :activity_type, :author
  validates_length_of :subject, :maximum => 255
  validates_inclusion_of :activity_type, :in => ACTIVITY_TYPES
  validates_inclusion_of :status, :in => ACTIVITY_STATUSES

  before_validation :set_default_status, on: :create

  scope :open, -> { where.not(status: ['completed', 'cancelled']) }
  scope :completed, -> { where(status: 'completed') }
  scope :by_planned_date, -> { order(planned_date: :asc) }
  scope :overdue, -> { where('planned_date < ? AND status NOT IN (?)', Date.today, ['completed', 'cancelled']) }

  safe_attributes 'activity_type',
                  'subject',
                  'description',
                  'assigned_to_id',
                  'planned_date',
                  'completed_date',
                  'status'

  def visible?(user = User.current)
    risk && risk.visible?(user)
  end

  def editable?(user = User.current)
    risk && risk.editable?(user)
  end

  def deletable?(user = User.current)
    editable?(user)
  end

  def project
    risk&.project
  end

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def open?
    !completed? && !cancelled?
  end

  def overdue?
    open? && planned_date && planned_date < Date.today
  end

  def complete!
    self.status = 'completed'
    self.completed_date = Date.today if completed_date.blank?
    save
  end

  def cancel!
    self.status = 'cancelled'
    save
  end

  def progress_percentage
    case status
    when 'planned' then 0
    when 'in_progress' then 50
    when 'completed' then 100
    when 'cancelled' then 0
    else 0
    end
  end

  def days_until_due
    return nil unless planned_date
    (planned_date - Date.today).to_i
  end

  def status_css_class
    case status
    when 'planned' then 'activity-planned'
    when 'in_progress' then 'activity-in-progress'
    when 'completed' then 'activity-completed'
    when 'cancelled' then 'activity-cancelled'
    else ''
    end
  end

  def last_note
    notes.recent.first
  end

  private

  def set_default_status
    self.status ||= 'planned'
  end
end
