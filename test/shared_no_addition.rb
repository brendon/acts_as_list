module Shared
  module NoAddition
    def setup
      (1..4).each { |counter| NoAdditionMixin.create! pos: counter, parent_id: 5 }
    end

    def test_insert
      new = NoAdditionMixin.create(parent_id: 20)
      assert_equal nil, new.pos
      assert !new.in_list?

      new = NoAdditionMixin.create(parent_id: 20)
      assert_equal nil, new.pos
    end

    def test_update_does_not_add_to_list
      new = NoAdditionMixin.create(parent_id: 20)
      new.update_attribute(:updated_at, Time.now) # force some change
      new.reload

      assert !new.in_list?
    end

  end
end
