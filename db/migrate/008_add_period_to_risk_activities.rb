migration_class = ActiveRecord::VERSION::MAJOR >= 7 ? ActiveRecord::Migration[7.0] : ActiveRecord::Migration[4.2]

class AddPeriodToRiskActivities < migration_class
  def change
    add_column :risk_activities, :period, :string
  end
end
