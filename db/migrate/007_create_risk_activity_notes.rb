migration_class = ActiveRecord::VERSION::MAJOR >= 7 ? ActiveRecord::Migration[7.0] : ActiveRecord::Migration[4.2]

class CreateRiskActivityNotes < migration_class
  def change
    create_table :risk_activity_notes do |t|
      t.integer  :risk_activity_id, :null => false
      t.text     :content,          :null => false
      t.integer  :author_id,        :null => false
      t.datetime :created_on,       :null => false
    end

    add_index :risk_activity_notes, :risk_activity_id
    add_index :risk_activity_notes, :author_id
  end
end
