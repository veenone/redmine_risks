class RiskTreatmentPlanSelection < ActiveRecord::Base
  belongs_to :risk
  belongs_to :risk_treatment_plan_setting

  validates :risk_id, presence: true
  validates :risk_treatment_plan_setting_id, presence: true
  validates :risk_treatment_plan_setting_id, uniqueness: { scope: :risk_id }
end
