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

class LockedTodoList < ActiveRecord::Base
  self.table_name = 'locked_todo_lists'
end

# A model whose default scope joins another table.
class LockedJoinedTodoItem < ActiveRecord::Base
  self.table_name = 'locked_todo_items'
  belongs_to :todo_list, class_name: 'LockedTodoList', optional: true
  default_scope { left_joins(:todo_list) }
  acts_as_list scope: :todo_list_id, lock_first: true
end

class LockFirstTestCase < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :locked_todo_items do |t|
      t.column :todo_list_id, :integer
      t.column :kind, :string
      t.column :position, :integer
      t.column :name, :string
    end

    ActiveRecord::Base.connection.create_table :locked_composite_todo_items, primary_key: [:first_id, :second_id] do |t|
      t.column :first_id, :integer, null: false
      t.column :second_id, :integer, null: false
      t.column :todo_list_id, :integer
      t.column :position, :integer
    end

    ActiveRecord::Base.connection.create_table :locked_todo_lists do |t|
      t.column :name, :string
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    [LockedTodoItem, LockedReadingTodoItem, LockedTopTodoItem, LockedArrayScopeTodoItem, LockedCompositeTodoItem,
     UnlockedTodoItem, LockedTodoList, LockedJoinedTodoItem].each(&:reset_column_information)
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

  # The statement right after BEGIN locks the list, and no other statement does. A later locking read can only be
  # with_lock, which reloads the item (SELECT table.* ... FOR UPDATE).
  def assert_list_locked_first(statements)
    start = statements.index { |sql| sql.match?(/\ABEGIN/i) } or flunk("no BEGIN in:\n#{statements.join("\n")}")
    assert_match LIST_LOCK, statements[start + 1].to_s, statements.join("\n")
    assert_equal 1, statements.grep(LIST_LOCK).size, statements.join("\n")
  end

  LIST_LOCK = /\ASELECT [^*]* FOR UPDATE\z/m
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

  def test_destroy_locks_the_list_first
    item = LockedTodoItem.find(@items[1].id)
    statements = capture_sql { item.destroy! }

    assert_list_locked_first statements
    assert_equal @items.values_at(0, 2, 3).map(&:id), list_ids
    assert_equal [1, 2, 3], list_positions
  end

  def test_locks_come_before_the_reads_of_a_callback_that_runs_when_the_item_is_loaded
    item = LockedReadingTodoItem.find(@items[3].id)
    statements = capture_sql { item.insert_at(2) }

    # The list, then with_lock, which reloads the item.
    assert_list_locked_first statements
    assert_equal @items.values_at(0, 3, 1, 2).map(&:id), list_ids

    item = LockedReadingTodoItem.find(@items[0].id)
    assert_list_locked_first capture_sql { item.destroy! }
    assert_equal [1, 2, 3], list_positions
  end

  def test_update_of_position_locks_before_the_validations_read
    item = LockedTodoItem.find(@items[3].id)
    statements = capture_sql { item.update!(position: 1) }

    assert_list_locked_first statements
    refute_empty plain_reads(statements), "the uniqueness validation reads"
    assert_equal @items.values_at(3, 0, 1, 2).map(&:id), list_ids
  end

  def test_update_without_validations_locks_first
    item = LockedTodoItem.find(@items[3].id)
    item.position = 1
    statements = capture_sql { item.save!(validate: false) }

    assert_list_locked_first statements
    assert_equal @items.values_at(3, 0, 1, 2).map(&:id), list_ids
  end

  def test_update_of_another_attribute_does_not_lock
    item = LockedTodoItem.find(@items[0].id)
    statements = capture_sql { item.update!(name: "renamed") }

    assert_empty locking_reads(statements)
  end

  def test_create_at_the_bottom_locks_the_list
    statements = capture_sql { LockedTodoItem.create!(todo_list_id: 1, name: "new") }

    assert_list_locked_first statements
  end

  def test_create_at_a_position_locks_the_list
    statements = capture_sql { LockedTodoItem.create!(todo_list_id: 1, name: "new", position: 2) }

    assert_list_locked_first statements
    assert_equal [1, 2, 3, 4, 5], list_positions
  end

  def test_create_at_the_top_locks_the_list
    statements = capture_sql { LockedTopTodoItem.create!(todo_list_id: 1) }

    assert_list_locked_first statements
    assert_equal [1, 2, 3, 4, 5], list_positions
  end

  def test_valid_outside_a_transaction_does_not_lock
    item = LockedTodoItem.find(@items[3].id)
    item.position = 1
    statements = capture_sql { assert item.valid? }

    assert_empty locking_reads(statements)
  end

  def test_insert_at_locks_the_list_before_it_reads
    item = LockedTodoItem.find(@items[3].id)
    statements = capture_sql { item.insert_at(2) }

    # The list, then with_lock, which reloads the item. The saves inside insert_at lock nothing more.
    assert_list_locked_first statements
    assert_equal @items.values_at(0, 3, 1, 2).map(&:id), list_ids
  end

  def test_move_to_top_and_move_to_bottom_lock_first
    item = LockedTodoItem.find(@items[1].id)

    assert_list_locked_first capture_sql { item.move_to_bottom }
    assert_equal @items.values_at(0, 2, 3, 1).map(&:id), list_ids
    assert_list_locked_first capture_sql { item.move_to_top }
    assert_equal @items.values_at(1, 0, 2, 3).map(&:id), list_ids
  end

  def test_move_higher_and_move_lower_lock_the_list_first
    item = LockedTodoItem.find(@items[1].id)

    assert_list_locked_first capture_sql { item.move_higher }
    assert_equal @items.values_at(1, 0, 2, 3).map(&:id), list_ids
    assert_list_locked_first capture_sql { item.move_lower }
    assert_equal @items.values_at(0, 1, 2, 3).map(&:id), list_ids
  end

  def test_scope_change_locks_both_lists_in_one_statement
    item = LockedTodoItem.find(@items[1].id)
    statements = capture_sql { item.update!(todo_list_id: 2) }

    assert_list_locked_first statements
    assert_match(/todo_list_id\W+ = \S+ OR \S+todo_list_id\W+ = /, locking_reads(statements).first)
    assert_equal 2, item.reload.todo_list_id
    assert_equal 2, item.position
    assert_equal [1, 2, 3], list_positions
  end

  def test_scope_change_to_a_position_locks_first
    item = LockedTodoItem.find(@items[1].id)
    statements = capture_sql { item.update!(todo_list_id: 2, position: 1) }

    assert_list_locked_first statements
    assert_equal [item.id], LockedTodoItem.where(todo_list_id: 2, position: 1).pluck(:id)
    assert_equal [1, 2], LockedTodoItem.where(todo_list_id: 2).order(:position).pluck(:position)
    assert_equal [1, 2, 3], list_positions
  end

  def test_array_scope_change
    first = LockedArrayScopeTodoItem.create!(todo_list_id: 3, kind: "a")
    LockedArrayScopeTodoItem.create!(todo_list_id: 3, kind: "a")
    LockedArrayScopeTodoItem.create!(todo_list_id: 3, kind: "b")

    statements = capture_sql { first.update!(kind: "b") }

    assert_list_locked_first statements
    assert_equal [1, 2], LockedArrayScopeTodoItem.where(todo_list_id: 3, kind: "b").order(:position).pluck(:position)
    assert_equal [1], LockedArrayScopeTodoItem.where(todo_list_id: 3, kind: "a").pluck(:position)
  end

  def test_composite_primary_key
    skip "composite primary keys need Rails 7.1" unless ActiveRecord.version >= Gem::Version.new("7.1")

    (1..3).each { |counter| LockedCompositeTodoItem.create!(first_id: counter, second_id: counter, todo_list_id: 1) }

    assert_list_locked_first capture_sql { LockedCompositeTodoItem.find([3, 3]).insert_at(1) }
    assert_equal [3, 1, 2], LockedCompositeTodoItem.order(:position).pluck(:first_id)
    assert_list_locked_first capture_sql { LockedCompositeTodoItem.find([3, 3]).destroy! }
    assert_equal [1, 2], LockedCompositeTodoItem.order(:position).pluck(:position)
  end

  def test_the_lock_leaves_out_the_joins_of_the_default_scope
    item = LockedJoinedTodoItem.find(@items[3].id)
    statements = capture_sql { item.insert_at(1) }

    # PostgreSQL refuses FOR UPDATE on the nullable side of an outer join, and a join would lock the joined rows too.
    assert_list_locked_first statements
    refute_match(/JOIN/, locking_reads(statements).first)
    assert_equal @items.values_at(3, 0, 1, 2).map(&:id), list_ids
  end

  def test_remove_from_list_locks_the_list_first
    item = LockedTodoItem.find(@items[1].id)

    assert_list_locked_first capture_sql { item.remove_from_list }
    assert_equal [1, 2, 3], list_positions.compact
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

# ActiveRecord generates position_in_database for a column named position. acts_as_list must leave it alone.
class LockFirstAttributeMethodsTest < LockFirstTestCase
  def test_position_in_database
    [LockedTodoItem, UnlockedTodoItem].each_with_index do |model, index|
      item = model.create!(todo_list_id: index + 1)
      item.position = 5
      assert_equal 1, item.position_in_database, model.name
    end
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

  def test_move_lower_in_a_transaction_that_has_not_read_yet
    item = LockedTodoItem.find(@items[3].id)
    race(hold_after: /\AUPDATE.*position.? [-+] 1/m, first: -> { LockedTodoItem.find(@items[0].id).insert_at(6) },
         second: -> { LockedTodoItem.transaction { item.move_lower } })

    assert_equal [1, 2, 3, 4, 5, 6], list_positions
  end

  def test_move_to_bottom_in_a_transaction_that_has_not_read_yet
    item = LockedTodoItem.find(@items[3].id)
    race(hold_after: /\AUPDATE.*position.? [-+] 1/m, first: -> { LockedTodoItem.find(@items[0].id).insert_at(6) },
         second: -> { LockedTodoItem.transaction { item.move_to_bottom } })

    assert_equal [1, 2, 3, 4, 5, 6], list_positions
  end

  def test_two_items_swap_lists_at_once
    other = (1..3).map { |counter| LockedTodoItem.create!(todo_list_id: 2, name: "other #{counter}") }
    race(hold_after: /\AUPDATE.*position.? [-+] 1/m, first: -> { LockedTodoItem.find(@items[0].id).update!(todo_list_id: 2) },
         second: -> { LockedTodoItem.find(other[0].id).update!(todo_list_id: 1) })

    assert_equal [1, 2, 3, 4, 5, 6], list_positions
    assert_equal [1, 2, 3], LockedTodoItem.where(todo_list_id: 2).order(:position).pluck(:position)
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
