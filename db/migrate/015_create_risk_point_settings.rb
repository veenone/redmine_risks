class CreateRiskPointSettings < ActiveRecord::Migration[5.2]
  def change
    # Impact Point Settings table
    create_table :risk_impact_point_settings do |t|
      t.integer :project_id, null: false
      t.integer :score, null: false
      t.string :label, null: false
      t.text :description
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :risk_impact_point_settings, [:project_id, :score], unique: true, name: 'idx_risk_impact_point_project_score'
    add_index :risk_impact_point_settings, :project_id
    add_foreign_key :risk_impact_point_settings, :projects

    # Probability Point Settings table
    create_table :risk_probability_point_settings do |t|
      t.integer :project_id, null: false
      t.integer :score, null: false
      t.string :label, null: false
      t.text :description
      t.integer :position, default: 0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :risk_probability_point_settings, [:project_id, :score], unique: true, name: 'idx_risk_probability_point_project_score'
    add_index :risk_probability_point_settings, :project_id
    add_foreign_key :risk_probability_point_settings, :projects
  end
end
