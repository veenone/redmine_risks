class AddRiskContextAndTreatmentFields < ActiveRecord::Migration[6.0]
  def change
    # Risk Context fields
    add_column :risks, :impacted_assets, :text
    add_column :risks, :vulnerabilities, :text
    add_column :risks, :consequences, :text
    add_column :risks, :counter_measures, :text

    # Risk Treatment fields
    add_column :risks, :risk_treatment, :text
    add_column :risks, :risk_treatment_owner_id, :integer
    add_column :risks, :risk_treatment_plan, :string

    # Add index for treatment owner foreign key
    add_index :risks, :risk_treatment_owner_id
  end
end
