# Examples to explore possible race conditions when caching custom computed values

In Rails, sometimes you will need to save counts or custom computed values, where the default counter cache will not be enough.

Maybe you want to…

* Update a counter cache when a value change and not only when the association is created or deleted
* Have a counter cache for complex “has many through” associations
* Keep a count for a scope of the association, like just the “positive reactions”, or the “completed orders”.
* Cache a sum or another calculation like the “account balance”

There are different techniques for caching this kind of values, but sometimes this type of calculation are prone to race conditions.

Here I want share a tool to help you understand why caching this kind of values are prone to race conditions, analyzing different ways to solve the “account balance” problem. Thinking maybe it could help you extrapolate to other situations.

## How can this examples help you?

You will be able to compare the threads of execution for each example.

Each example will run a "transaction" (not db transaction) where it will create four `entries` in an `account` with an `amount` of `100` and calculate the `balance` of the `account` after the creation of each `entry`. Expecting a final balance of `400`.

Each example calculates the `balance` in a slightly different way. For example one adds the amount of each entry to the current `account.balance`, like this:


```ruby
class Account < ExampleRecord
  has_many :entries

  def create_entry(amount:)
    entry = entries.create(amount: amount)
    update_balance_with(entry)
  end

  def update_balance_with(entry)
    balance = self.balance + entry.amount
    update!(balance: balance)
  end
end
```

And other sums the `amount` of all `account.entries` with ruby, each time that an entry is created, like this:

```ruby
class Account < ExampleRecord
  has_many :entries

  def create_entry(amount:)
    entry = entries.create(amount: amount)
    update_balance
  end

  def update_balance
    balance = entries.balance
    update!(balance: balance)
  end
end

class Entry < ExampleRecord
  belongs_to :account, touch: true

  def self.balance
    sum(&:amount)
  end
end
```

In other examples the sum is done in the database, other examples use `with_lock` in different places, and other examples use the class method `ExampleRecord.update_counters` from rails.

Each example will run the "transaction" using three different methods:

* `SerialTransaction` - That will create the entries serially in the same thread.
* `ThreadsTransaction` - That will create each entry and update the balance in a different thread.
* `ForksTransaction` - That will create each entry and update the balance in a different process, using fork.

For the `ThreadsTransaction` and `ForksTransactions` it will run the transaction until a run returns a different `balance` than the expected of `400`, or if the number of runs equals the parameter `max_runs_per_transaction_type` that has `5` as default value.

When you run an example you will find an output like:

```
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
# [1] Record created: 07
# [2] Record created: 08
# [1] Balance calculated: 100
# [0] Record created: 09
# [2] Balance calculated: 300
# [3] Record created: 10
# [0] Balance calculated: 300
# [3] Balance calculated: 400
# [1] Balance saved: 100
# [2] Balance saved: 300
# [0] Balance saved: 300
# [3] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction
# [1] Record created: 11
# [1] Balance calculated: 100
# [2] Record created: 12
# [2] Balance calculated: 200
# [3] Record created: 13
# [3] Balance calculated: 300
# [0] Record created: 14
# [0] Balance calculated: 400
# [2] Balance saved: 200
# [3] Balance saved: 300
# [1] Balance saved: 100
# [0] Balance saved: 400
# Output: 400
# 
# Run with ThreadsTransaction
# [1] Record created: 15
# [1] Balance calculated: 100
# [2] Record created: 16
# [2] Balance calculated: 200
# [3] Record created: 17
# [3] Balance calculated: 300
# [0] Record created: 18
# [0] Balance calculated: 400
# [2] Balance saved: 200
# [0] Balance saved: 400
# [1] Balance saved: 100
# [3] Balance saved: 300
# Output: 300
# 
# Run with ForksTransaction
# [2] Record created: 20
# [1] Record created: 19
# [2] Balance calculated: 200
# [0] Record created: 21
# [1] Balance calculated: 300
# [0] Balance calculated: 300
# [3] Record created: 22
# [3] Balance calculated: 400
# [3] Balance saved: 400
# [2] Balance saved: 200
# [0] Balance saved: 300
# [1] Balance saved: 300
# Output: 300
```

To explain what that means, we can zoom in to the output of the last run in the `ThreadsTransaction`...

```
# Run with ThreadsTransaction
# [1] Record created: 15
# [1] Balance calculated: 100
# [2] Record created: 16
# [2] Balance calculated: 200
# [3] Record created: 17
# [3] Balance calculated: 300
# [0] Record created: 18
# [0] Balance calculated: 400
# [2] Balance saved: 200
# [0] Balance saved: 400
# [1] Balance saved: 100
# [3] Balance saved: 300
# Output: 300
```

The number in brackets (`[]`) is an index of the current thread of execution of each created `entry`. So you will be able to compare how each part of the process is executed.

For example in the previous log we can see some, maybe unexpected, things like:

* The thread [0] created the record after the other three threads.
* The thread [3] calculates the balance before the last record is created, but is the last that saves the balance, giving us a bad result at the end.

## How to run the examples

1. **Install the dependencies** with `bundle install`.

2. **Database setup** - run the command:

```
ruby db/setup.rb
```

3. **Run the examples** with `ruby examples/<file name>`. For example:

```
ruby example/00_example.rb
```

4. **Change the seeds**  on `db/seeds.rb` and re-run `ruby db/setup.rb` to test different scenarios.
