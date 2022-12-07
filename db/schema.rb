require_relative "config"

ActiveRecord::Schema.define do
  create_table :accounts do |t|
    t.integer :balance, default: 0
    t.integer :entries_count
    t.timestamps
  end

  create_table :entries do |t|
    t.integer :account_id
    t.integer :amount
    t.timestamps
  end

  add_index :entries, :account_id
end
