require_relative "config"

ActiveRecord::Base.logger = nil

class Account < ExampleRecord
  has_many :entries

  def create_entry(amount:)
    entry = entries.create(amount: amount)
    log_entry_created(entry)
    update_balance
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

  def self.balance
    sum(:amount)
  end
end

ExampleRunner.run

# Run with SerialTransaction
# [0] Record created: 19
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Record created: 20
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Record created: 21
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Record created: 22
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction
# [1] Record created: 23
# [1] Balance calculated: 100
# [2] Record created: 25
# [0] Record created: 26
# [2] Balance calculated: 300
# [3] Record created: 24
# [0] Balance calculated: 400
# [3] Balance calculated: 400
# [1] Balance saved: 100
# [0] Balance saved: 400
# [3] Balance saved: 400
# [2] Balance saved: 300
# Output: 300
# 
# Run with ForksTransaction
# [1] Record created: 27
# [0] Record created: 28
# [2] Record created: 29
# [1] Balance calculated: 300
# [0] Balance calculated: 300
# [2] Balance calculated: 300
# [3] Record created: 30
# [3] Balance calculated: 400
# [2] Balance saved: 300
# [1] Balance saved: 300
# [0] Balance saved: 300
# [3] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction
# [1] Record created: 31
# [0] Record created: 33
# [2] Record created: 32
# [1] Balance calculated: 300
# [3] Record created: 34
# [0] Balance calculated: 300
# [2] Balance calculated: 400
# [3] Balance calculated: 400
# [2] Balance saved: 400
# [0] Balance saved: 300
# [3] Balance saved: 400
# [1] Balance saved: 300
# Output: 300