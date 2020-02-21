# frozen_string_literal: true

require 'helper'

class TestMoveBetweenLists < Minitest::Test
  class Section < ActiveRecord::Base
    has_many :items
  end

  class Item < ActiveRecord::Base
    belongs_to :section
    acts_as_list scope: :section, sequential_updates: true
  end

  def setup
    ActiveRecord::Base.connection.create_table :sections do |t|
    end

    ActiveRecord::Base.connection.create_table :items do |t|
      t.column :section_id, :integer
      t.column :position, :integer
    end

    ActiveRecord::Base.connection.add_index :items, %i[position section_id], unique: true

    ActiveRecord::Base.connection.schema_cache.clear!
    [Section, Item].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end

  def test_move_to_another_section
    section1 = Section.create
    section1_item1 = Item.create section: section1
    section1_item2 = Item.create section: section1
    section1_item3 = Item.create section: section1

    section2 = Section.create
    section2_item1 = Item.create section: section2
    section2_item2 = Item.create section: section2
    section2_item3 = Item.create section: section2

    section1_item2.update! section: section2

    assert_equal [section1.id, 1], [section1_item1.section_id, section1_item1.position]
    assert_equal [section2.id, 4], [section1_item2.section_id, section1_item2.position]
    assert_equal [section1.id, 3], [section1_item3.section_id, section1_item3.position] # Shouldn't this be position 2?

    assert_equal [section2.id, 1], [section2_item1.section_id, section2_item1.position]
    assert_equal [section2.id, 2], [section2_item2.section_id, section2_item2.position]
    assert_equal [section2.id, 3], [section2_item3.section_id, section2_item3.position]
  end
end
