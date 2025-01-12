class CreateSubscriptionLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_logs do |t|
      t.belongs_to :subscription, null: false, foreign_key: true

      t.decimal :amount, precision: 10, scale: 2
      t.string :status

      t.datetime :created_at, null: false
    end
  end
end
