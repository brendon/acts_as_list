# frozen_string_literal: true

require 'helper'
require 'ancestry'

class Node < ActiveRecord::Base
  acts_as_list scope: [:ancestry]
  has_ancestry cache_depth: true
end

class NoUpdateForAncestryParentChangeTestCase < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :nodes do |t|
      t.column :position, :integer
      t.column :ancestry, :string
      t.column :ancestry_depth, :integer
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    Node.reset_column_information
    super
  end

  def teardown
    teardown_db
    super
  end
end

class NoUpdateForAncestryParentChangeTest < NoUpdateForAncestryParentChangeTestCase
  def setup
    super

    @parent = Node.create!(position: 1)

    @node = Node.create!(position: 1)
    @node.update(parent: @parent)

    @child_1, @child_2 = (1..2).map do |counter|
      child = Node.create!(position: counter)
      child.update(parent: @node)
      child
    end
  end

  def test_update
    @node.update parent: nil

    assert_equal 2, @child_2.reload.position
    assert_equal 1, @child_1.reload.position
  end
end
