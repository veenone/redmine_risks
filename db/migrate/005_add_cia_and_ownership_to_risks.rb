migration_class = ActiveRecord::VERSION::MAJOR >= 7 ? ActiveRecord::Migration[7.0] : ActiveRecord::Migration[4.2]

class AddCiaAndOwnershipToRisks < migration_class
  def change
    add_column :risks, :confidentiality, :integer
    add_column :risks, :integrity, :integer
    add_column :risks, :availability, :integer
    add_column :risks, :level_of_significance, :integer
    add_column :risks, :action_owner_id, :integer
    add_column :risks, :risk_owner_id, :integer
    add_column :risks, :probability_point, :integer
    add_column :risks, :impact_point, :integer
  end
end