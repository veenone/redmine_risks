class CreateRiskRegistriesAndAreas < ActiveRecord::Migration[6.0]
  def change
    # Create project-scoped risk categories table (separate from Enumeration)
    create_table :risk_category_entries do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.string :code, limit: 10  # Short code for Risk ID prefix
      t.text :description
      t.integer :position, default: 1
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_category_entries, :project_id
    add_index :risk_category_entries, [:project_id, :name], unique: true
    add_index :risk_category_entries, [:project_id, :code], unique: true

    # Create project-scoped risk registry (risk definitions/types)
    create_table :risk_registries do |t|
      t.integer :project_id, null: false
      t.integer :risk_category_entry_id
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_registries, :project_id
    add_index :risk_registries, :risk_category_entry_id
    add_index :risk_registries, [:project_id, :name], unique: true

    # Create project-scoped areas registry
    create_table :risk_areas do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :risk_areas, :project_id
    add_index :risk_areas, [:project_id, :name], unique: true
  end
end
