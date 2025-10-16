# frozen_string_literal: true

require 'helper'

# Composite foreign keys were introduced in Rails 7.2
if ActiveRecord::VERSION::MAJOR == 7 && ActiveRecord::VERSION::MINOR >= 2 || ActiveRecord::VERSION::MAJOR > 7
  class CompositeForeignKeyParent < ActiveRecord::Base
    self.table_name = 'composite_foreign_key_parents'
  end

  class CompositeForeignKeyChild < ActiveRecord::Base
    self.table_name = 'composite_foreign_key_children'

    # Composite foreign key relationship
    belongs_to :composite_foreign_key_parent,
      foreign_key: [:parent_id, :child_key],
      primary_key: [:id, :name],
      optional: false

    acts_as_list scope: [:parent_id, :child_key, :category]
  end

  class CompositeForeignKeyTestCase < Minitest::Test
    def setup
      ActiveRecord::Base.connection.create_table :composite_foreign_key_parents do |t|
        t.string :name
        t.timestamps
      end

      ActiveRecord::Base.connection.create_table :composite_foreign_key_children do |t|
        t.integer :parent_id
        t.string :child_key
        t.string :category
        t.integer :position
        t.timestamps
      end

      ActiveRecord::Base.connection.schema_cache.clear!
      [CompositeForeignKeyParent, CompositeForeignKeyChild].each(&:reset_column_information)

      # Set up the has_many association dynamically
      CompositeForeignKeyParent.has_many :composite_foreign_key_children,
        foreign_key: [:parent_id, :child_key],
        primary_key: [:id, :name],
        dependent: :destroy
    end

    def teardown
      teardown_db
    end

    def test_allows_destroying_parent_with_composite_foreign_key_children
      parent = CompositeForeignKeyParent.create!(name: 'test')
      child1 = CompositeForeignKeyChild.create!(
        parent_id: parent.id,
        child_key: 'test',
        category: 'A',
        position: 1
      )
      child2 = CompositeForeignKeyChild.create!(
        parent_id: parent.id,
        child_key: 'test',
        category: 'A',
        position: 2
      )

      # When parent is destroyed with dependent: :destroy, it will destroy children
      # The child's destroyed_via_scope? method will be called
      # Without the fix, this raises: NoMethodError: undefined method 'to_sym' for an instance of Array
      assert parent.destroy
      assert_equal 0, CompositeForeignKeyChild.count
    end

    def test_allows_destroying_child_with_composite_foreign_key
      parent = CompositeForeignKeyParent.create!(name: 'test')
      child = CompositeForeignKeyChild.create!(
        parent_id: parent.id,
        child_key: 'test',
        category: 'A',
        position: 1
      )

      assert child.destroy
    end
  end
end
