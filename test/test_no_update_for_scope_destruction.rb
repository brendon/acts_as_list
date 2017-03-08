require 'helper'

class DestructionTodoList < ActiveRecord::Base
  has_many :destruction_todo_items, dependent: :destroy
end

class DestructionTodoItem < ActiveRecord::Base
  belongs_to :destruction_todo_list
  acts_as_list scope: :destruction_todo_list
end

class NoUpdateForScopeDestructionTestCase < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :destruction_todo_lists do |t|
    end

    ActiveRecord::Base.connection.create_table :destruction_todo_items do |t|
      t.column :position, :integer
      t.column :destruction_todo_list_id, :integer
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    [DestructionTodoList, DestructionTodoItem].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end

  class NoUpdateForScopeDestructionTest < NoUpdateForScopeDestructionTestCase
    def setup
      super
      @list = DestructionTodoList.create!

      @item_1, @item_2, @item_3 = (1..3).map { |counter| DestructionTodoItem.create!(position: counter, destruction_todo_list_id: @list.id) }
    end

    def test_no_update_children_when_parent_destroyed
      # mock = MiniTest::Mock.new
      # mock.expects(:decrement_positions_on_lower_items).once
      @list.destroy
    end

  end
end