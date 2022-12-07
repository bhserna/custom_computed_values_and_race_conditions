require_relative "config"

ActiveRecord::Base.logger = nil

class Account < ExampleRecord
  has_many :entries

  def create_entry(amount:)
    entry = entries.create(amount: amount)
    update_balance_with(entry)
  end

  def update_balance_with(entry)
    Account.update_counters(id, balance: entry.amount)
    log_balance_saved "+ #{entry.amount}"
  end
end

class Entry < ExampleRecord
  belongs_to :account, touch: true

  after_create { log_entry_created(self) }

  def self.balance
    sum(:amount)
  end
end

ExampleRunner.run(max_runs_per_transaction_type: 2)

# Run with SerialTransaction
# [0] Record created: 11
# [0] Balance saved: + 100
# [1] Record created: 12
# [1] Balance saved: + 100
# [2] Record created: 13
# [2] Balance saved: + 100
# [3] Record created: 14
# [3] Balance saved: + 100
# Output: 400
# 
# Run with ThreadsTransaction (run 1)
# [1] Record created: 15
# [0] Record created: 16
# [1] Balance saved: + 100
# [3] Record created: 17
# [2] Record created: 18
# [0] Balance saved: + 100
# [3] Balance saved: + 100
# [2] Balance saved: + 100
# Output: 400
# 
# Run with ThreadsTransaction (run 2)
# [2] Record created: 19
# [0] Record created: 20
# [2] Balance saved: + 100
# [0] Balance saved: + 100
# [3] Record created: 21
# [3] Balance saved: + 100
# [1] Record created: 22
# [1] Balance saved: + 100
# Output: 400
# 
# Run with ForksTransaction (run 1)
# [0] Record created: 23
# [1] Record created: 24
# [2] Record created: 25
# [0] Balance saved: + 100
# [3] Record created: 26
# [1] Balance saved: + 100
# [2] Balance saved: + 100
# [3] Balance saved: + 100
# Output: 400
# 
# Run with ForksTransaction (run 2)
# [1] Record created: 27
# [0] Record created: 29
# [2] Record created: 28
# [0] Balance saved: + 100
# [1] Balance saved: + 100
# [2] Balance saved: + 100
# [3] Record created: 30
# [3] Balance saved: + 100
# Output: 400