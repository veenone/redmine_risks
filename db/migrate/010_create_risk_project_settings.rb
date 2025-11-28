class CreateRiskProjectSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :risk_project_settings do |t|
      t.integer :project_id, null: false
      t.string :cia_assessment_mode, default: 'levels', null: false
      t.timestamps
    end

    add_index :risk_project_settings, :project_id, unique: true
    add_foreign_key :risk_project_settings, :projects
  end
end
