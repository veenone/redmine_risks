class AddNewFieldsToRisks < ActiveRecord::Migration[6.0]
  def change
    # Add new registry references
    add_column :risks, :risk_category_entry_id, :integer
    add_column :risks, :risk_registry_id, :integer
    add_column :risks, :risk_area_id, :integer

    # Add new fields for Risk Entry
    add_column :risks, :threat_event, :text
    add_column :risks, :risk_id_code, :string, limit: 20  # Manual entry: 1st char of category + 6 digits
    add_column :risks, :remark, :text

    # Add indexes for quick lookups
    add_index :risks, :risk_category_entry_id
    add_index :risks, :risk_registry_id
    add_index :risks, :risk_area_id
    add_index :risks, :risk_id_code
    add_index :risks, [:project_id, :risk_id_code], unique: true
  end
end
