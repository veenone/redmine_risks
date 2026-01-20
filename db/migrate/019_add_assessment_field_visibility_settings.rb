class AddAssessmentFieldVisibilitySettings < ActiveRecord::Migration[6.1]
  def change
    add_column :risk_project_settings, :show_probability_field, :boolean, default: false
    add_column :risk_project_settings, :show_impact_field, :boolean, default: false
    add_column :risk_project_settings, :show_magnitude_field, :boolean, default: false
  end
end
