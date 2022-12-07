class SerialTransaction
  def self.run_many_times(count)
    count.times.map { run }.map(&:to_f)
  end

  def self.run
    account = Account.first
    account.entries.delete_all
    account.update!(balance: 0)

    4.times.map do |i|
      Thread.current[:index] = i
      Account.first.create_entry(amount: 100)
    end

    Account.first.balance
  end
end

class ForksTransaction
  def self.run_many_times(count)
    count.times.map { run }.map(&:to_f)
  end

  def self.run
    account = Account.first
    account.entries.delete_all
    account.update!(balance: 0)

    4.times.map do |i|
      fork do
        Thread.current[:index] = i
        Account.first.create_entry(amount: 100)
      end
    end

    Process.waitall
    Account.first.balance
  end
end

class ThreadsTransaction
  def self.run_many_times(count)
    count.times.map { run }.map(&:to_f)
  end

  def self.run
    account = Account.first
    account.entries.delete_all
    account.update!(balance: 0)

    threads = 4.times.map do |i|
      Thread.new do
        Thread.current[:index] = i
        Account.first.create_entry(amount: 100) 
      end
    end

    threads.each(&:join)
    Account.first.balance
  end
end

class ExampleRunner
  def self.run(max_runs_per_transaction_type: 5)
    puts
    puts "Run with SerialTransaction"
    output = SerialTransaction.run
    puts "Output: #{output}"

    output = nil

    max_runs_per_transaction_type.times do |run|
      puts
      puts "Run with ThreadsTransaction (run #{run + 1})"
      output = ThreadsTransaction.run
      puts "Output: #{output}"
      break if output != 400
    end

    output = nil

    max_runs_per_transaction_type.times do |run|
      puts
      puts "Run with ForksTransaction (run #{run + 1})"
      output = ForksTransaction.run
      puts "Output: #{output}"
      break if output != 400
    end
  end
end

module ExampleLogger
  def log_entry_created(entry)
    puts "[#{Thread.current[:index]}] Record created: #{entry.id.to_s.chars.last(2).join}"
  end

  def log_balance_calculated(balance)
    puts "[#{Thread.current[:index]}] Balance calculated: #{balance}"
  end

  def log_balance_saved(balance)
    puts "[#{Thread.current[:index]}] Balance saved: #{balance}"
  end
end

class ExampleRecord < ActiveRecord::Base
  self.abstract_class = true

  include ExampleLogger

  def random_sleep
    sleep [0.1, 0.2, 0.5].sample
  end

  def big_random_sleep
    sleep [0.5, 1, 2].sample
  end
end