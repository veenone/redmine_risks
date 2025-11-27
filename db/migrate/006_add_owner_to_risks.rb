migration_class = ActiveRecord::VERSION::MAJOR >= 7 ? ActiveRecord::Migration[7.0] : ActiveRecord::Migration[4.2]

class AddOwnerToRisks < migration_class
  def change
    add_column :risks, :owner_id, :integer
    add_index :risks, :owner_id
  end
end
