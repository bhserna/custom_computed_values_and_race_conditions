require_relative "config"

ActiveRecord::Base.logger = nil

class Account < ExampleRecord
  has_many :entries

  def create_entry(amount:)
    entries.create(amount: amount)
    update_balance
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
# [0] Record created: 71
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Record created: 72
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Record created: 73
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Record created: 74
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 1)
# [2] Record created: 77
# [0] Record created: 76
# [3] Record created: 75
# [1] Record created: 78
# [2] Balance calculated: 400
# [2] Balance saved: 400
# [1] Balance calculated: 400
# [1] Balance saved: 400
# [3] Balance calculated: 400
# [3] Balance saved: 400
# [0] Balance calculated: 400
# [0] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 2)
# [0] Record created: 79
# [3] Record created: 80
# [0] Balance calculated: 100
# [2] Record created: 81
# [1] Record created: 82
# [0] Balance saved: 100
# [1] Balance calculated: 400
# [1] Balance saved: 400
# [3] Balance calculated: 400
# [3] Balance saved: 400
# [2] Balance calculated: 400
# [2] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 1)
# [1] Record created: 83
# [2] Record created: 84
# [0] Record created: 85
# [3] Record created: 86
# [0] Balance calculated: 400
# [0] Balance saved: 400
# [1] Balance calculated: 400
# [1] Balance saved: 400
# [2] Balance calculated: 400
# [2] Balance saved: 400
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 2)
# [1] Record created: 88
# [0] Record created: 87
# [2] Record created: 89
# [3] Record created: 90
# [0] Balance calculated: 300
# [0] Balance saved: 300
# [1] Balance calculated: 300
# [1] Balance saved: 300
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400