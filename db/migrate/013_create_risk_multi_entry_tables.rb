class CreateRiskMultiEntryTables < ActiveRecord::Migration[6.0]
  def change
    # Impacted Assets (multi-entry)
    create_table :risk_assets do |t|
      t.integer :risk_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.timestamps
    end
    add_index :risk_assets, :risk_id
    add_index :risk_assets, [:risk_id, :name]

    # Vulnerabilities (multi-entry)
    create_table :risk_vulnerabilities do |t|
      t.integer :risk_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.timestamps
    end
    add_index :risk_vulnerabilities, :risk_id
    add_index :risk_vulnerabilities, [:risk_id, :name]

    # Consequences (multi-entry)
    create_table :risk_consequences do |t|
      t.integer :risk_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.timestamps
    end
    add_index :risk_consequences, :risk_id
    add_index :risk_consequences, [:risk_id, :name]

    # Counter-measures (multi-entry)
    create_table :risk_counter_measures do |t|
      t.integer :risk_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.timestamps
    end
    add_index :risk_counter_measures, :risk_id
    add_index :risk_counter_measures, [:risk_id, :name]

    # Mitigations (multi-entry) - part of Risk Treatment Plan
    create_table :risk_mitigations do |t|
      t.integer :risk_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.timestamps
    end
    add_index :risk_mitigations, :risk_id
    add_index :risk_mitigations, [:risk_id, :name]

    # Preventions (multi-entry) - part of Risk Treatment Plan
    create_table :risk_preventions do |t|
      t.integer :risk_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 1
      t.timestamps
    end
    add_index :risk_preventions, :risk_id
    add_index :risk_preventions, [:risk_id, :name]
  end
end
