# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_01_10_000002) do
  create_table "subscription_logs", force: :cascade do |t|
    t.integer "subscription_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.string "status"
    t.datetime "created_at", null: false
    t.index ["subscription_id"], name: "index_subscription_logs_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "retry_attempts", default: 0
    t.datetime "next_retry_at"
    t.decimal "remaining_balance", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "subscription_logs", "subscriptions"
end
