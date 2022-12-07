require_relative "config"

ActiveRecord::Base.logger = nil

class Account < ExampleRecord
  has_many :entries

  def create_entry(amount:)
    entry = entries.create(amount: amount)
    log_entry_created(entry)
    update_balance_with(entry)
  end

  def update_balance_with(entry)
    balance = self.balance + entry.amount
    log_balance_calculated(balance)

    random_sleep

    update!(balance: balance)
    log_balance_saved(balance)
  end
end

class Entry < ExampleRecord
  belongs_to :account, touch: true
end

ExampleRunner.run

# Run with SerialTransaction
# [0] Record created: 03
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Record created: 04
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Record created: 05
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Record created: 06
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction
# [3] Record created: 08
# [3] Balance calculated: 100
# [1] Record created: 09
# [1] Balance calculated: 100
# [0] Record created: 07
# [0] Balance calculated: 100
# [2] Record created: 10
# [2] Balance calculated: 100
# [0] Balance saved: 100
# [1] Balance saved: 100
# [3] Balance saved: 100
# [2] Balance saved: 100
# Output: 100
# 
# Run with ForksTransaction
# [0] Record created: 11
# [0] Balance calculated: 100
# [2] Record created: 12
# [2] Balance calculated: 100
# [1] Record created: 13
# [1] Balance calculated: 100
# [3] Record created: 14
# [3] Balance calculated: 100
# [1] Balance saved: 100
# [3] Balance saved: 100
# [0] Balance saved: 100
# [2] Balance saved: 100
# Output: 100