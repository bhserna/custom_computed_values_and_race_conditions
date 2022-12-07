require_relative "config"

ActiveRecord::Base.logger = nil

class Account < ExampleRecord
  has_many :entries

  after_touch :update_balance

  def create_entry(amount:)
    entries.create(amount: amount)
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

ExampleRunner.run

# Run with SerialTransaction
# [0] Record created: 00
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Record created: 01
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Record created: 02
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Record created: 03
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 1)
# [0] Record created: 04
# [1] Record created: 05
# [3] Record created: 06
# [2] Record created: 07
# [0] Balance calculated: 100
# [0] Balance saved: 100
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 2)
# [3] Record created: 08
# [3] Balance calculated: 100
# [0] Record created: 09
# [2] Record created: 10
# [1] Record created: 11
# [3] Balance saved: 100
# [0] Balance calculated: 200
# [0] Balance saved: 200
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [1] Balance calculated: 400
# [1] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 3)
# [1] Record created: 12
# [1] Balance calculated: 100
# [3] Record created: 13
# [2] Record created: 14
# [0] Record created: 15
# [1] Balance saved: 100
# [3] Balance calculated: 200
# [3] Balance saved: 200
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [0] Balance calculated: 400
# [0] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 4)
# [2] Record created: 16
# [2] Balance calculated: 100
# [3] Record created: 17
# [1] Record created: 18
# [0] Record created: 19
# [2] Balance saved: 100
# [3] Balance calculated: 200
# [3] Balance saved: 200
# [0] Balance calculated: 300
# [0] Balance saved: 300
# [1] Balance calculated: 400
# [1] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction (run 5)
# [1] Record created: 20
# [1] Balance calculated: 100
# [2] Record created: 21
# [3] Record created: 22
# [0] Record created: 23
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
# [1] Record created: 25
# [0] Record created: 24
# [2] Record created: 26
# [1] Balance calculated: 100
# [3] Record created: 27
# [1] Balance saved: 100
# [0] Balance calculated: 200
# [0] Balance saved: 200
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 2)
# [2] Record created: 28
# [0] Record created: 29
# [1] Record created: 30
# [0] Balance calculated: 100
# [3] Record created: 31
# [0] Balance saved: 100
# [2] Balance calculated: 200
# [2] Balance saved: 200
# [1] Balance calculated: 300
# [1] Balance saved: 300
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 3)
# [3] Record created: 32
# [1] Record created: 33
# [0] Record created: 34
# [3] Balance calculated: 100
# [2] Record created: 35
# [3] Balance saved: 100
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [0] Balance calculated: 400
# [0] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 4)
# [1] Record created: 36
# [0] Record created: 37
# [0] Balance calculated: 100
# [3] Record created: 38
# [2] Record created: 39
# [0] Balance saved: 100
# [1] Balance calculated: 200
# [1] Balance saved: 200
# [2] Balance calculated: 300
# [2] Balance saved: 300
# [3] Balance calculated: 400
# [3] Balance saved: 400
# Output: 400
# 
# Run with ForksTransaction (run 5)
# [1] Record created: 41
# [2] Record created: 40
# [0] Record created: 42
# [0] Balance calculated: 100
# [3] Record created: 43
# [0] Balance saved: 100
# [2] Balance calculated: 200
# [2] Balance saved: 200
# [3] Balance calculated: 300
# [3] Balance saved: 300
# [1] Balance calculated: 400
# [1] Balance saved: 400
# Output: 400