# frozen_string_literal: true

require 'helper'
require 'timeout'

class LockedTodoItem < ActiveRecord::Base
  self.table_name = 'locked_todo_items'
  validates :name, uniqueness: { scope: :todo_list_id }, allow_nil: true
  acts_as_list scope: :todo_list_id, lock_first: true
end

# A model that reads whenever a record is loaded, as an application callback can.
class LockedReadingTodoItem < ActiveRecord::Base
  self.table_name = 'locked_todo_items'
  after_find { self.class.where(todo_list_id: 0).exists? }
  acts_as_list scope: :todo_list_id, lock_first: true
end

class LockedTopTodoItem < ActiveRecord::Base
  self.table_name = 'locked_todo_items'
  acts_as_list scope: :todo_list_id, lock_first: true, add_new_at: :top
end

class LockedArrayScopeTodoItem < ActiveRecord::Base
  self.table_name = 'locked_todo_items'
  acts_as_list scope: [:todo_list_id, :kind], lock_first: true
end

class LockedCompositeTodoItem < ActiveRecord::Base
  self.table_name = 'locked_composite_todo_items'
  self.primary_key = [:first_id, :second_id]
  acts_as_list scope: :todo_list_id, lock_first: true
end

class UnlockedTodoItem < ActiveRecord::Base
  self.table_name = 'locked_todo_items'
  acts_as_list scope: :todo_list_id
end

class LockFirstTestCase < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :locked_todo_items do |t|
      t.column :todo_list_id, :integer
      t.column :kind, :string
      t.column :position, :integer
      t.column :name, :string
    end
    # As most applications have it. With this index, a destroy that locks its own row before the rows below it
    # deadlocks with a destroy of the item above (see LockFirstConcurrencyTest).
    ActiveRecord::Base.connection.add_index :locked_todo_items, [:todo_list_id, :position]

    ActiveRecord::Base.connection.create_table :locked_composite_todo_items, primary_key: [:first_id, :second_id] do |t|
      t.column :first_id, :integer, null: false
      t.column :second_id, :integer, null: false
      t.column :todo_list_id, :integer
      t.column :position, :integer
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    [LockedTodoItem, LockedReadingTodoItem, LockedTopTodoItem, LockedArrayScopeTodoItem, LockedCompositeTodoItem, UnlockedTodoItem].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end

  private

  def row_locks?
    ENV.fetch("DB") != "sqlite"
  end

  # The statements of the block, without schema queries. BEGIN and COMMIT are kept.
  def capture_sql
    statements = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      statements << payload[:sql] unless payload[:name] == "SCHEMA"
    end
    yield
    statements
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def locking_reads(statements)
    statements.grep(/FOR UPDATE/)
  end

  def plain_reads(statements)
    statements.grep(/\ASELECT/).grep_v(/FOR UPDATE/)
  end

  # Every locking read comes before the first plain read, and the first one right after BEGIN.
  def assert_locks_first(statements, count)
    locks = locking_reads(statements)
    assert_equal count, locks.size, statements.join("\n")
    return if count.zero?

    start = statements.index { |sql| sql.match?(/\ABEGIN/i) } or flunk("no BEGIN in:\n#{statements.join("\n")}")
    assert_equal locks, statements[start + 1, count], "the locks must be the first statements of the transaction"
  end

  # The first item of the list: every change to a list locks it before anything else.
  HEAD_LOCK = /ORDER BY .*position\W+ ASC LIMIT 1 FOR UPDATE/
  ITEM_LOCK = /WHERE\W+locked_todo_items\W+id\W+ (=|IN)/
  POSITION_RANGE = /position\W+ >/
end

class LockFirstOrderTest < LockFirstTestCase
  def setup
    super
    skip "SQLite has no row locks: ActiveRecord sends no FOR UPDATE" unless row_locks?

    @items = (1..4).map { |counter| LockedTodoItem.create!(todo_list_id: 1, name: "item #{counter}") }
    LockedTodoItem.create!(todo_list_id: 2, name: "other list")
  end

  def test_lock_first_is_off_by_default
    statements = capture_sql do
      item = UnlockedTodoItem.find(@items[0].id)
      item.update!(position: 3)
      item.move_lower
      item.destroy!
      UnlockedTodoItem.create!(todo_list_id: 1, position: 1)
    end

    assert_empty locking_reads(statements)
    assert_equal false, UnlockedTodoItem.new.send(:lock_first?)
    assert_equal false, UnlockedTodoItem.acts_as_list_options[:lock_first]
    assert_equal true, LockedTodoItem.acts_as_list_options[:lock_first]
  end

  def test_destroy_locks_the_list_head_the_item_and_the_items_below_it_first
    item = LockedTodoItem.find(@items[1].id)
    statements = capture_sql { item.destroy! }

    assert_locks_first statements, 3
    assert_match HEAD_LOCK, locking_reads(statements)[0]
    assert_match ITEM_LOCK, locking_reads(statements)[1]
    assert_match POSITION_RANGE, locking_reads(statements)[2]
    assert_equal @items.values_at(0, 2, 3).map(&:id), list_ids
    assert_equal [1, 2, 3], list_positions
  end

  def test_locks_come_before_the_reads_of_a_callback_that_runs_when_the_item_is_loaded
    item = LockedReadingTodoItem.find(@items[3].id)
    statements = capture_sql { item.insert_at(2) }

    # The list head, the item, the items in between, and then with_lock, which reloads the item.
    assert_locks_first statements, 4
    assert_equal @items.values_at(0, 3, 1, 2).map(&:id), list_ids

    item = LockedReadingTodoItem.find(@items[0].id)
    assert_locks_first capture_sql { item.destroy! }, 3
    assert_equal [1, 2, 3], list_positions
  end

  def test_update_of_position_locks_before_the_validations_read
    item = LockedTodoItem.find(@items[3].id)
    statements = capture_sql { item.update!(position: 1) }

    assert_locks_first statements, 3
    assert_match HEAD_LOCK, locking_reads(statements)[0]
    assert_match ITEM_LOCK, locking_reads(statements)[1]
    assert_match POSITION_RANGE, locking_reads(statements)[2]
    refute_empty plain_reads(statements), "the uniqueness validation reads"
    assert_equal @items.values_at(3, 0, 1, 2).map(&:id), list_ids
  end

  def test_update_without_validations_locks_first
    item = LockedTodoItem.find(@items[3].id)
    item.position = 1
    statements = capture_sql { item.save!(validate: false) }

    assert_locks_first statements, 3
    assert_equal @items.values_at(3, 0, 1, 2).map(&:id), list_ids
  end

  def test_update_of_another_attribute_does_not_lock
    item = LockedTodoItem.find(@items[0].id)
    statements = capture_sql { item.update!(name: "renamed") }

    assert_locks_first statements, 0
  end

  def test_create_at_the_bottom_does_not_lock
    statements = capture_sql { LockedTodoItem.create!(todo_list_id: 1, name: "new") }

    assert_locks_first statements, 0
  end

  def test_create_at_a_position_locks_the_items_from_that_position_on
    statements = capture_sql { LockedTodoItem.create!(todo_list_id: 1, name: "new", position: 2) }

    assert_locks_first statements, 2
    assert_match HEAD_LOCK, locking_reads(statements)[0]
    assert_match POSITION_RANGE, locking_reads(statements)[1]
    assert_equal [1, 2, 3, 4, 5], list_positions
  end

  def test_create_at_the_top_locks_the_list
    statements = capture_sql { LockedTopTodoItem.create!(todo_list_id: 1) }

    assert_locks_first statements, 2
    assert_match HEAD_LOCK, locking_reads(statements)[0]
    refute_match POSITION_RANGE, locking_reads(statements)[1]
    assert_equal [1, 2, 3, 4, 5], list_positions
  end

  def test_valid_outside_a_transaction_does_not_lock
    item = LockedTodoItem.find(@items[3].id)
    item.position = 1
    statements = capture_sql { assert item.valid? }

    assert_empty locking_reads(statements)
  end

  def test_insert_at_locks_the_items_in_between_before_it_reads
    item = LockedTodoItem.find(@items[3].id)
    statements = capture_sql { item.insert_at(2) }

    # The list head, the item, then the items between the two positions, then with_lock, which reloads the item.
    # The saves inside insert_at lock nothing more.
    assert_locks_first statements, 4
    assert_match HEAD_LOCK, locking_reads(statements)[0]
    assert_match ITEM_LOCK, locking_reads(statements)[1]
    assert_match POSITION_RANGE, locking_reads(statements)[2]
    assert_equal @items.values_at(0, 3, 1, 2).map(&:id), list_ids
  end

  def test_move_to_top_and_move_to_bottom_lock_first
    item = LockedTodoItem.find(@items[1].id)

    assert_locks_first capture_sql { item.move_to_bottom }, 4
    assert_equal @items.values_at(0, 2, 3, 1).map(&:id), list_ids
    assert_locks_first capture_sql { item.move_to_top }, 4
    assert_equal @items.values_at(1, 0, 2, 3).map(&:id), list_ids
  end

  def test_move_higher_and_move_lower_lock_the_neighbour_and_the_item_first
    item = LockedTodoItem.find(@items[1].id)

    assert_locks_first capture_sql { item.move_higher }, 3
    assert_equal @items.values_at(1, 0, 2, 3).map(&:id), list_ids
    assert_locks_first capture_sql { item.move_lower }, 3
    assert_equal @items.values_at(0, 1, 2, 3).map(&:id), list_ids
  end

  def test_scope_change_locks_the_item_and_the_items_below_it_in_the_old_list
    item = LockedTodoItem.find(@items[1].id)
    statements = capture_sql { item.update!(todo_list_id: 2) }

    # The head of the old list, the head of the new list, the item, the items below it in the old list.
    assert_locks_first statements, 4
    assert_match HEAD_LOCK, locking_reads(statements)[0]
    assert_match HEAD_LOCK, locking_reads(statements)[1]
    assert_equal 2, item.reload.todo_list_id
    assert_equal 2, item.position
    assert_equal [1, 2, 3], list_positions
  end

  def test_scope_change_to_a_position_also_locks_the_items_it_moves_in_the_new_list
    item = LockedTodoItem.find(@items[1].id)
    statements = capture_sql { item.update!(todo_list_id: 2, position: 1) }

    assert_locks_first statements, 5
    assert_equal [item.id], LockedTodoItem.where(todo_list_id: 2, position: 1).pluck(:id)
    assert_equal [1, 2], LockedTodoItem.where(todo_list_id: 2).order(:position).pluck(:position)
    assert_equal [1, 2, 3], list_positions
  end

  def test_array_scope_change
    first = LockedArrayScopeTodoItem.create!(todo_list_id: 3, kind: "a")
    LockedArrayScopeTodoItem.create!(todo_list_id: 3, kind: "a")
    LockedArrayScopeTodoItem.create!(todo_list_id: 3, kind: "b")

    statements = capture_sql { first.update!(kind: "b") }

    assert_locks_first statements, 4
    assert_equal [1, 2], LockedArrayScopeTodoItem.where(todo_list_id: 3, kind: "b").order(:position).pluck(:position)
    assert_equal [1], LockedArrayScopeTodoItem.where(todo_list_id: 3, kind: "a").pluck(:position)
  end

  def test_composite_primary_key
    skip "composite primary keys need Rails 7.1" unless ActiveRecord.version >= Gem::Version.new("7.1")

    (1..3).each { |counter| LockedCompositeTodoItem.create!(first_id: counter, second_id: counter, todo_list_id: 1) }

    assert_locks_first capture_sql { LockedCompositeTodoItem.find([3, 3]).insert_at(1) }, 4
    assert_equal [3, 1, 2], LockedCompositeTodoItem.order(:position).pluck(:first_id)
    assert_locks_first capture_sql { LockedCompositeTodoItem.find([3, 3]).destroy! }, 3
    assert_equal [1, 2], LockedCompositeTodoItem.order(:position).pluck(:position)
  end

  def test_no_lock_in_a_no_update_block
    item = LockedTodoItem.find(@items[3].id)
    statements = capture_sql do
      LockedTodoItem.acts_as_list_no_update do
        item.update!(position: 1)
        item.destroy!
      end
    end

    assert_empty locking_reads(statements)
  end

  private

  def list_ids
    LockedTodoItem.where(todo_list_id: 1).order(:position).pluck(:id)
  end

  def list_positions
    LockedTodoItem.where(todo_list_id: 1).order(:position).pluck(:position)
  end
end

# Two connections change one list at once. The first one stops with its transaction open. The second one
# must wait for it at its first statement, and then work on the positions the first one committed.
#
# On MariaDB 11.6.2+ (innodb_snapshot_isolation) the second one fails without lock_first: true:
# "Record has changed since last read in table 'locked_todo_items'".
class LockFirstConcurrencyTest < LockFirstTestCase
  def setup
    super
    skip "SQLite has no row locks" unless row_locks?

    @items = (1..6).map { |counter| LockedTodoItem.create!(todo_list_id: 1, name: "item #{counter}") }
  end

  def test_two_destroys_at_once
    race(hold_after: /\ADELETE/, first: -> { LockedTodoItem.find(@items[1].id).destroy! },
         second: -> { LockedTodoItem.find(@items[0].id).destroy! })

    assert_equal @items.values_at(2, 3, 4, 5).map(&:id), list_ids
    assert_equal [1, 2, 3, 4], list_positions
  end

  # The first destroy stops right after its first locking read. Every change locks the first item of the list
  # before anything else, so two changes to one list cannot deadlock on its rows. When a destroy locked its own
  # row first, the destroy of the item above it took this item's index record with its lock of the rows below,
  # and then waited for this row, while this destroy's DELETE waited for that index record: a deadlock.
  def test_two_destroys_at_once_when_the_lower_one_holds_only_its_first_lock
    race(hold_after: /\ASELECT .* FOR UPDATE\z/m, first: -> { LockedTodoItem.find(@items[1].id).destroy! },
         second: -> { LockedTodoItem.find(@items[0].id).destroy! })

    assert_equal @items.values_at(2, 3, 4, 5).map(&:id), list_ids
    assert_equal [1, 2, 3, 4], list_positions
  end

  # The other order of the locks in a destroy (the rows from the item down, then the item) deadlocks here.
  def test_destroy_that_holds_only_its_first_lock_and_a_move_at_once
    race(hold_after: /\ASELECT .* FOR UPDATE\z/m, first: -> { LockedTodoItem.find(@items[1].id).destroy! },
         second: -> { LockedTodoItem.find(@items[4].id).move_to_top })

    assert_equal @items.values_at(4, 0, 2, 3, 5).map(&:id), list_ids
    assert_equal [1, 2, 3, 4, 5], list_positions
  end

  def test_two_moves_at_once
    race(hold_after: /\AUPDATE.*position.? [-+] 1/m, first: -> { LockedTodoItem.find(@items[0].id).insert_at(3) },
         second: -> { LockedTodoItem.find(@items[5].id).insert_at(2) })

    assert_equal @items.values_at(1, 5, 2, 0, 3, 4).map(&:id), list_ids
    assert_equal [1, 2, 3, 4, 5, 6], list_positions
  end

  def test_move_and_destroy_at_once
    race(hold_after: /\AUPDATE.*position.? [-+] 1/m, first: -> { LockedTodoItem.find(@items[4].id).move_to_top },
         second: -> { LockedTodoItem.find(@items[1].id).destroy! })

    assert_equal @items.values_at(4, 0, 2, 3, 5).map(&:id), list_ids
    assert_equal [1, 2, 3, 4, 5], list_positions
  end

  def test_two_updates_of_position_at_once
    race(hold_after: /\AUPDATE.*position.? [-+] 1/m, first: -> { LockedTodoItem.find(@items[0].id).update!(position: 3) },
         second: -> { LockedTodoItem.find(@items[5].id).update!(position: 2) })

    assert_equal @items.values_at(1, 5, 2, 0, 3, 4).map(&:id), list_ids
    assert_equal [1, 2, 3, 4, 5, 6], list_positions
  end

  def test_two_inserts_at_a_position_at_once
    race(hold_after: /\AINSERT/, first: -> { LockedTodoItem.create!(todo_list_id: 1, name: "first", position: 1) },
         second: -> { LockedTodoItem.create!(todo_list_id: 1, name: "second", position: 1) })

    assert_equal %w[second first], LockedTodoItem.where(todo_list_id: 1).order(:position).limit(2).pluck(:name)
    assert_equal (1..8).to_a, list_positions
  end

  private

  def list_ids
    LockedTodoItem.where(todo_list_id: 1).order(:position).pluck(:id)
  end

  def list_positions
    LockedTodoItem.where(todo_list_id: 1).order(:position).pluck(:position)
  end

  # Runs +first+ on its own connection and stops it after its first statement that matches +hold_after+.
  # Runs +second+ on another connection until it has sent its first lock, then lets +first+ go.
  def race(hold_after:, first:, second:)
    held = Queue.new
    release = Queue.new
    second_locking = Queue.new
    listener = RaceListener.new(hold_after, held, release, second_locking)
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record", listener)

    first_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:lock_first_race_role] = :first
        first.call
      end
    end
    assert pop(held), "the first change never reached #{hold_after.inspect}"

    second_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:lock_first_race_role] = :second
        second.call
      end
    end
    assert pop(second_locking), "the second change never locked a row"
    sleep 0.3 # the lock request is on its way to the server: let it start to wait
    assert second_thread.alive?, "the second change must wait for the first one"
    release << true

    # Thread#value raises what the thread raised.
    [first_thread.value, second_thread.value]
  ensure
    release << true
    [first_thread, second_thread].compact.each { |thread| thread.join(10) }
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  def pop(queue)
    Timeout.timeout(10) { queue.pop }
  rescue Timeout::Error
    nil
  end

  class RaceListener
    def initialize(hold_after, held, release, second_locking)
      @hold_after = hold_after
      @held = held
      @release = release
      @second_locking = second_locking
      @holding = true
    end

    def start(_name, _id, payload)
      return unless Thread.current[:lock_first_race_role] == :second

      @second_locking << true if payload[:sql].match?(/FOR UPDATE/)
    end

    def finish(_name, _id, payload)
      return unless Thread.current[:lock_first_race_role] == :first
      return unless @holding && payload[:sql].match?(@hold_after)

      @holding = false
      @held << true
      begin
        Timeout.timeout(15) { @release.pop }
      rescue Timeout::Error
        nil
      end
    end
  end
end
