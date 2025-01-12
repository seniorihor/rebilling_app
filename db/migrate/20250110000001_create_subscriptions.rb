class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :status, null: false, default: 'pending'
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.integer :retry_attempts, default: 0
      t.datetime :next_retry_at
      t.decimal :remaining_balance, precision: 10, scale: 2

      t.timestamps
    end
  end
end
