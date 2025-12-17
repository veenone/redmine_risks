class AddConfigurableListsAndCustomOwner < ActiveRecord::Migration[6.1]
  def change
    # Strategy entry settings (configurable strategy options per project)
    create_table :risk_strategy_settings do |t|
      t.integer :project_id, null: false
      t.string :key, null: false
      t.string :label, null: false
      t.text :description
      t.integer :position
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_strategy_settings, :project_id
    add_index :risk_strategy_settings, [:project_id, :key], unique: true

    # Probability entry settings (for probability dropdown - not points, but level labels)
    create_table :risk_probability_entry_settings do |t|
      t.integer :project_id, null: false
      t.string :key, null: false
      t.string :label, null: false
      t.text :description
      t.integer :position
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_probability_entry_settings, :project_id
    add_index :risk_probability_entry_settings, [:project_id, :key], unique: true, name: 'idx_prob_entry_settings_project_key'

    # Impact entry settings (for impact dropdown - not points, but level labels)
    create_table :risk_impact_entry_settings do |t|
      t.integer :project_id, null: false
      t.string :key, null: false
      t.string :label, null: false
      t.text :description
      t.integer :position
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_impact_entry_settings, :project_id
    add_index :risk_impact_entry_settings, [:project_id, :key], unique: true, name: 'idx_impact_entry_settings_project_key'

    # Treatment plan entries (configurable, multi-selectable)
    create_table :risk_treatment_plan_settings do |t|
      t.integer :project_id, null: false
      t.string :key, null: false
      t.string :label, null: false
      t.text :description
      t.integer :position
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_treatment_plan_settings, :project_id
    add_index :risk_treatment_plan_settings, [:project_id, :key], unique: true, name: 'idx_treatment_plan_settings_project_key'

    # Join table for multi-selectable treatment plans
    create_table :risk_treatment_plan_selections do |t|
      t.integer :risk_id, null: false
      t.integer :risk_treatment_plan_setting_id, null: false
      t.timestamps
    end
    add_index :risk_treatment_plan_selections, :risk_id
    add_index :risk_treatment_plan_selections, :risk_treatment_plan_setting_id, name: 'idx_treatment_plan_selections_setting'
    add_index :risk_treatment_plan_selections, [:risk_id, :risk_treatment_plan_setting_id], unique: true, name: 'idx_risk_treatment_plan_selections_unique'

    # Custom owner name for risks
    add_column :risks, :custom_risk_owner_name, :string
    add_column :risks, :custom_treatment_owner_name, :string

    # Project-level entry lists for vulnerabilities, consequences, counter-measures
    create_table :risk_vulnerability_entries do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_vulnerability_entries, :project_id
    add_index :risk_vulnerability_entries, [:project_id, :name], name: 'idx_vulnerability_entries_project_name'

    create_table :risk_consequence_entries do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_consequence_entries, :project_id
    add_index :risk_consequence_entries, [:project_id, :name], name: 'idx_consequence_entries_project_name'

    create_table :risk_counter_measure_entries do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_counter_measure_entries, :project_id
    add_index :risk_counter_measure_entries, [:project_id, :name], name: 'idx_counter_measure_entries_project_name'

    # Link existing risk entries to project-level entries
    add_column :risk_vulnerabilities, :risk_vulnerability_entry_id, :integer
    add_column :risk_consequences, :risk_consequence_entry_id, :integer
    add_column :risk_counter_measures, :risk_counter_measure_entry_id, :integer

    add_index :risk_vulnerabilities, :risk_vulnerability_entry_id, name: 'idx_risk_vuln_entry'
    add_index :risk_consequences, :risk_consequence_entry_id, name: 'idx_risk_conseq_entry'
    add_index :risk_counter_measures, :risk_counter_measure_entry_id, name: 'idx_risk_cm_entry'
  end
end
