# frozen_string_literal: true

module Shared
  module NoAddition
    def setup
      (1..4).each { |counter| NoAdditionMixin.create! pos: counter, parent_id: 5 }
    end

    def test_insert
      new = NoAdditionMixin.create(parent_id: 20)
      assert_nil new.pos
      assert !new.in_list?

      new = NoAdditionMixin.create(parent_id: 20)
      assert_nil new.pos
    end

    def test_update_does_not_add_to_list
      new = NoAdditionMixin.create(parent_id: 20)
      new.update_attribute(:updated_at, Time.now) # force some change
      new.reload

      assert !new.in_list?
    end

    def test_update_scope_does_not_add_to_list
      new = NoAdditionMixin.create

      new.update_attribute(:parent_id, 20)
      new.reload
      assert !new.in_list?

      new.update_attribute(:parent_id, 5)
      new.reload
      assert !new.in_list?
    end

    def test_collision_avoidance_with_explicit_position
      first = NoAdditionMixin.create(parent_id: 20, pos: 1)
      second = NoAdditionMixin.create(parent_id: 20, pos: 1)
      third = NoAdditionMixin.create(parent_id: 30, pos: 1)

      first.reload
      second.reload
      third.reload

      assert_equal 2, first.pos
      assert_equal 1, second.pos
      assert_equal 1, third.pos

      first.update(pos: 1)

      first.reload
      second.reload

      assert_equal 1, first.pos
      assert_equal 2, second.pos

      first.update(parent_id: 30)

      first.reload
      second.reload
      third.reload

      assert_equal 1, first.pos
      assert_equal 30, first.parent_id
      assert_equal 1, second.pos
      assert_equal 20, second.parent_id
      assert_equal 2, third.pos
      assert_equal 30, third.parent_id
    end
  end
end
