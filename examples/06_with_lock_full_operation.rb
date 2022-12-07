require_relative "config"

ActiveRecord::Base.logger = nil

class Account < ExampleRecord
  has_many :entries

  def create_entry(amount:)
    with_lock do
      entries.create(amount: amount)
      update_balance
    end
  end

  def update_balance
    balance = entries.balance
    log_balance_calculated(balance)

    random_sleep

    update!(balance: balance)
    log_balance_saved(balance)
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
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Record created: 12
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Record created: 13
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Record created: 14
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 1)
# [0] Record created: 15
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Record created: 16
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [3] Record created: 17
# [3] Balance calculated: 300
# [3] Balance saved: 300
# [2] Record created: 18
# [2] Balance calculated: 400
# [2] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 2)
# [1] Record created: 19
# [1] Balance calculated: 100
# [1] Balance saved: 100
# [2] Record created: 20
# [2] Balance calculated: 200
# [2] Balance saved: 200
# [3] Record created: 21
# [3] Balance calculated: 300
# [3] Balance saved: 300
# [0] Record created: 22
# [0] Balance calculated: 400
# [0] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 1)
# [1] Record created: 23
# [1] Balance calculated: 100
# [1] Balance saved: 100
# [0] Record created: 24
# [0] Balance calculated: 200
# [0] Balance saved: 200
# [2] Record created: 25
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Record created: 26
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 2)
# [0] Record created: 27
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [2] Record created: 28
# [2] Balance calculated: 200
# [2] Balance saved: 200
# [1] Record created: 29
# [1] Balance calculated: 300
# [1] Balance saved: 300
# [3] Record created: 30
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400