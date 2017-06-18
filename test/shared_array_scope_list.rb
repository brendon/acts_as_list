module Shared
  module ArrayScopeList
    def setup
      (1..4).each { |counter| ArrayScopeListMixin.create! pos: counter, parent_id: 5, parent_type: 'ParentClass' }
      (1..4).each { |counter| ArrayScopeListMixin.create! pos: counter, parent_id: 6, parent_type: 'ParentClass' }
    end

    def test_reordering
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 2).first.move_lower
      assert_equal [1, 3, 2, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 2).first.move_higher
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 1).first.move_to_bottom
      assert_equal [2, 3, 4, 1], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 1).first.move_to_top
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 2).first.move_to_bottom
      assert_equal [1, 3, 4, 2], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 4).first.move_to_top
      assert_equal [4, 1, 3, 2], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 4).first.insert_at(4)
      assert_equal [1, 3, 2, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:pos)
    end

    def test_move_to_bottom_with_next_to_last_item
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)
      ArrayScopeListMixin.where(id: 3).first.move_to_bottom
      assert_equal [1, 2, 4, 3], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)
    end

    def test_next_prev
      assert_equal ArrayScopeListMixin.where(id: 2).first, ArrayScopeListMixin.where(id: 1).first.lower_item
      assert_nil ArrayScopeListMixin.where(id: 1).first.higher_item
      assert_equal ArrayScopeListMixin.where(id: 3).first, ArrayScopeListMixin.where(id: 4).first.higher_item
      assert_nil ArrayScopeListMixin.where(id: 4).first.lower_item
    end

    def test_injection
      item = ArrayScopeListMixin.new(parent_id: 1, parent_type: 'ParentClass')
      assert_equal "pos", item.position_column
    end

    def test_insert
      new = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?

      new = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 2, new.pos
      assert !new.first?
      assert new.last?

      new = ArrayScopeListMixin.acts_as_list_no_update { ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass') }
      assert_equal_or_nil $default_position,new.pos
      assert_equal $default_position.is_a?(Integer), new.first?
      assert !new.last?

      new = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 3, new.pos
      assert !new.first?
      assert new.last?

      new = ArrayScopeListMixin.create(parent_id: 0, parent_type: 'ParentClass')
      assert_equal 1, new.pos
      assert new.first?
      assert new.last?
    end

    def test_insert_at
      new = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 1, new.pos

      new = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 2, new.pos

      new = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 3, new.pos

      new_noup = ArrayScopeListMixin.acts_as_list_no_update { ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass') }
      assert_equal_or_nil $default_position,new_noup.pos

      new4 = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 4, new4.pos

      new4.insert_at(3)
      assert_equal 3, new4.pos

      new.reload
      assert_equal 4, new.pos

      new.insert_at(2)
      assert_equal 2, new.pos

      new4.reload
      assert_equal 4, new4.pos

      new5 = ArrayScopeListMixin.create(parent_id: 20, parent_type: 'ParentClass')
      assert_equal 5, new5.pos

      new5.insert_at(1)
      assert_equal 1, new5.pos

      new4.reload
      assert_equal 5, new4.pos

      new_noup.reload
      assert_equal_or_nil $default_position, new_noup.pos
    end

    def test_delete_middle
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 2).first.destroy

      assert_equal [1, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      assert_equal 1, ArrayScopeListMixin.where(id: 1).first.pos
      assert_equal 2, ArrayScopeListMixin.where(id: 3).first.pos
      assert_equal 3, ArrayScopeListMixin.where(id: 4).first.pos

      ArrayScopeListMixin.where(id: 1).first.destroy

      assert_equal [3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      assert_equal 1, ArrayScopeListMixin.where(id: 3).first.pos
      assert_equal 2, ArrayScopeListMixin.where(id: 4).first.pos

      ArrayScopeListMixin.acts_as_list_no_update { ArrayScopeListMixin.where(id: 3).first.destroy }

      assert_equal [4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      assert_equal 2, ArrayScopeListMixin.where(id: 4).first.pos
    end

    def test_remove_from_list_should_then_fail_in_list?
      assert_equal true, ArrayScopeListMixin.where(id: 1).first.in_list?
      ArrayScopeListMixin.where(id: 1).first.remove_from_list
      assert_equal false, ArrayScopeListMixin.where(id: 1).first.in_list?
    end

    def test_remove_from_list_should_set_position_to_nil
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 2).first.remove_from_list

      assert_equal 1,   ArrayScopeListMixin.where(id: 1).first.pos
      assert_nil        ArrayScopeListMixin.where(id: 2).first.pos
      assert_equal 2,   ArrayScopeListMixin.where(id: 3).first.pos
      assert_equal 3,   ArrayScopeListMixin.where(id: 4).first.pos
    end

    def test_remove_before_destroy_does_not_shift_lower_items_twice
      assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      ArrayScopeListMixin.where(id: 2).first.remove_from_list
      ArrayScopeListMixin.where(id: 2).first.destroy

      assert_equal [1, 3, 4], ArrayScopeListMixin.where(parent_id: 5, parent_type: 'ParentClass').order('pos').map(&:id)

      assert_equal 1, ArrayScopeListMixin.where(id: 1).first.pos
      assert_equal 2, ArrayScopeListMixin.where(id: 3).first.pos
      assert_equal 3, ArrayScopeListMixin.where(id: 4).first.pos
    end
  end
end
