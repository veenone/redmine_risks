class RiskProjectSetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project

  # CIA Assessment modes
  CIA_MODE_LEVELS = 'levels'.freeze    # Low/Medium/High
  CIA_MODE_BOOLEAN = 'boolean'.freeze  # Yes/No

  CIA_MODES = [CIA_MODE_LEVELS, CIA_MODE_BOOLEAN].freeze

  validates :project_id, presence: true, uniqueness: true
  validates :cia_assessment_mode, inclusion: { in: CIA_MODES }

  safe_attributes 'cia_assessment_mode'

  # Find or initialize settings for a project
  def self.for_project(project)
    find_or_initialize_by(project: project)
  end

  # Check if using boolean (Yes/No) mode
  def boolean_cia_mode?
    cia_assessment_mode == CIA_MODE_BOOLEAN
  end

  # Check if using levels (Low/Medium/High) mode
  def levels_cia_mode?
    cia_assessment_mode == CIA_MODE_LEVELS
  end
end
