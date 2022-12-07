require_relative "config"

ActiveRecord::Base.logger = nil

class Account < ExampleRecord
  has_many :entries
  after_touch :update_balance

  def create_entry(amount:)
    entries.create(amount: amount)
  end

  def update_balance
    with_lock do
      balance = entries.balance
      log_balance_calculated(balance)

      random_sleep

      update!(balance: balance)
      log_balance_saved(balance)
    end
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
# [0] Record created: 91
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Record created: 92
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Record created: 93
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Record created: 94
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 1)
# [1] Record created: 95
# [0] Record created: 96
# [3] Record created: 98
# [2] Record created: 97
# [1] Balance calculated: 100
# [1] Balance saved: 100
# [0] Balance calculated: 200
# [0] Balance saved: 200
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 2)
# [1] Record created: 99
# [1] Balance calculated: 100
# [2] Record created: 00
# [3] Record created: 01
# [0] Record created: 02
# [1] Balance saved: 100
# [2] Balance calculated: 200
# [2] Balance saved: 200
# [3] Balance calculated: 300
# [3] Balance saved: 300
# [0] Balance calculated: 400
# [0] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 1)
# [1] Record created: 04
# [2] Record created: 03
# [0] Record created: 05
# [3] Record created: 06
# [1] Balance calculated: 100
# [1] Balance saved: 100
# [0] Balance calculated: 200
# [0] Balance saved: 200
# [3] Balance calculated: 300
# [3] Balance saved: 300
# [2] Balance calculated: 400
# [2] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 2)
# [1] Record created: 07
# [0] Record created: 08
# [2] Record created: 09
# [1] Balance calculated: 100
# [3] Record created: 10
# [1] Balance saved: 100
# [0] Balance calculated: 200
# [0] Balance saved: 200
# [3] Balance calculated: 300
# [3] Balance saved: 300
# [2] Balance calculated: 400
# [2] Balance saved: 400
# Output: 400