migration_class = ActiveRecord::VERSION::MAJOR >= 7 ? ActiveRecord::Migration[7.0] : ActiveRecord::Migration[4.2]

class CreateRiskActivities < migration_class
  def change
    create_table :risk_activities do |t|
      t.integer  :risk_id,         :null => false
      t.string   :activity_type,   :null => false
      t.string   :subject,         :null => false
      t.text     :description
      t.integer  :assigned_to_id
      t.date     :planned_date
      t.date     :completed_date
      t.string   :status,          :null => false, :default => 'planned'
      t.string   :period
      t.integer  :author_id,       :null => false
      t.datetime :created_on,      :null => false
      t.datetime :updated_on,      :null => false
    end

    add_index :risk_activities, :risk_id
    add_index :risk_activities, :assigned_to_id
    add_index :risk_activities, :status
  end
end
