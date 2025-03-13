migration_class = ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration

class FixNilRiskStatus < migration_class
  def up
    # Update any risks with nil status to "open"
    execute "UPDATE risks SET status = 'open' WHERE status IS NULL"
  end

  def down
    # No down migration needed
  end
end