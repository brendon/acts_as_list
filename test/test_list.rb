# NOTE: following now done in helper.rb (better Readability)
require 'helper'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Schema.verbose = false

def setup_db(position_options = {})
  # AR caches columns options like defaults etc. Clear them!
  ActiveRecord::Base.connection.schema_cache.clear!
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :pos, :integer, position_options
      t.column :active, :boolean, :default => true
      t.column :parent_id, :integer
      t.column :parent_type, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end
end

def setup_db_with_default
  setup_db :default => 0
end

# Returns true if ActiveRecord is rails3 version
def rails_3
  defined?(ActiveRecord::VERSION) && ActiveRecord::VERSION::MAJOR >= 3
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
  self.table_name = 'mixins'
  attr_accessible :active, :parent_id, :parent_type
end

class ProtectedMixin < ActiveRecord::Base
  self.table_name = 'mixins'
  attr_protected :active
end

class ProtectedListMixin < ProtectedMixin
  acts_as_list :column => "pos"
end

class UnProtectedMixin < ActiveRecord::Base
  self.table_name = 'mixins'
end

class UnProtectedListMixin < UnProtectedMixin
  acts_as_list :column => "pos"
end


class ListMixin < Mixin
  acts_as_list :column => "pos", :scope => :parent
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
  if rails_3
    validates :pos, :presence => true
  else
    validates_presence_of :pos
  end
end

class ListWithStringScopeMixin < Mixin
  acts_as_list :column => "pos", :scope => 'parent_id = #{parent_id}'
end

class ArrayScopeListMixin < Mixin
  acts_as_list :column => "pos", :scope => [:parent_id, :parent_type]
end

class ZeroBasedMixin < Mixin
  acts_as_list :column => "pos", :top_of_list => 0, :scope => [:parent_id]
end

class DefaultScopedMixin < Mixin
  acts_as_list :column => "pos"
  default_scope { order('pos ASC') }
end

class DefaultScopedWhereMixin < Mixin
  acts_as_list :column => "pos"
  default_scope { order('pos ASC').where(:active => true) }
end

class TopAdditionMixin < Mixin
  acts_as_list :column => "pos", :add_new_at => :top, :scope => :parent_id
end

class ActsAsListTestCase < Test::Unit::TestCase
  # No default test required a this class is abstract.
  # Need for test/unit.
  undef_method :default_test if method_defined?(:default_test)

  def teardown
    teardown_db
  end
end

class ZeroBasedTest < ActsAsListTestCase
  include Shared::ZeroBased

  def setup
    setup_db
    super
  end
end

class ZeroBasedTestWithDefault < ActsAsListTestCase
  include Shared::ZeroBased

  def setup
    setup_db_with_default
    super
  end
end

class ListTest < ActsAsListTestCase
  include Shared::List

  def setup
    setup_db
    super
  end
end

class ListTestWithDefault < ActsAsListTestCase
  include Shared::List

  def setup
    setup_db_with_default
    super
  end
end

class ListSubTest < ActsAsListTestCase
  include Shared::ListSub

  def setup
    setup_db
    super
  end
end

class ListSubTestWithDefault < ActsAsListTestCase
  include Shared::ListSub

  def setup
    setup_db_with_default
    super
  end
end

class ArrayScopeListTest < ActsAsListTestCase
  include Shared::ArrayScopeList

  def setup
    setup_db
    super
  end
end

class ArrayScopeListTestWithDefault < ActsAsListTestCase
  include Shared::ArrayScopeList

  def setup
    setup_db_with_default
    super
  end
end

class DefaultScopedTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| DefaultScopedMixin.create!({:pos => counter}) }
  end

  def test_insert
    new = DefaultScopedMixin.create
    assert_equal 5, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedMixin.create
    assert_equal 6, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedMixin.create
    assert_equal 7, new.pos
    assert !new.first?
    assert new.last?
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.find(:all).map(&:id)

    DefaultScopedMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], DefaultScopedMixin.find(:all).map(&:id)

    DefaultScopedMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.find(:all).map(&:id)

    DefaultScopedMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], DefaultScopedMixin.find(:all).map(&:id)

    DefaultScopedMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.find(:all).map(&:id)

    DefaultScopedMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], DefaultScopedMixin.find(:all).map(&:id)

    DefaultScopedMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], DefaultScopedMixin.find(:all).map(&:id)
  end

  def test_insert_at
    new = DefaultScopedMixin.create
    assert_equal 5, new.pos

    new = DefaultScopedMixin.create
    assert_equal 6, new.pos

    new = DefaultScopedMixin.create
    assert_equal 7, new.pos

    new4 = DefaultScopedMixin.create
    assert_equal 8, new4.pos

    new4.insert_at(2)
    assert_equal 2, new4.pos

    new.reload
    assert_equal 8, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 3, new4.pos

    new5 = DefaultScopedMixin.create
    assert_equal 9, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 4, new4.pos
  end

  def test_update_position
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.find(:all).map(&:id)
    DefaultScopedMixin.find(2).set_list_position(4)
    assert_equal [1, 3, 4, 2], DefaultScopedMixin.find(:all).map(&:id)
    DefaultScopedMixin.find(2).set_list_position(2)
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.find(:all).map(&:id)
    DefaultScopedMixin.find(1).set_list_position(4)
    assert_equal [2, 3, 4, 1], DefaultScopedMixin.find(:all).map(&:id)
    DefaultScopedMixin.find(1).set_list_position(1)
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.find(:all).map(&:id)
  end

end

class DefaultScopedWhereTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| DefaultScopedWhereMixin.create! :pos => counter, :active => false }
  end

  def test_insert
    new = DefaultScopedWhereMixin.create
    assert_equal 5, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedWhereMixin.create
    assert_equal 6, new.pos
    assert !new.first?
    assert new.last?

    new = DefaultScopedWhereMixin.create
    assert_equal 7, new.pos
    assert !new.first?
    assert new.last?
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.where(:active => false).map(&:id)

    DefaultScopedWhereMixin.where(:active => false).find(2).move_lower
    assert_equal [1, 3, 2, 4], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)

    DefaultScopedWhereMixin.where(:active => false).find(2).move_higher
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)

    DefaultScopedWhereMixin.where(:active => false).find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)

    DefaultScopedWhereMixin.where(:active => false).find(1).move_to_top
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)

    DefaultScopedWhereMixin.where(:active => false).find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)

    DefaultScopedWhereMixin.where(:active => false).find(4).move_to_top
    assert_equal [4, 1, 3, 2], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)
  end

  def test_insert_at
    new = DefaultScopedWhereMixin.create
    assert_equal 5, new.pos

    new = DefaultScopedWhereMixin.create
    assert_equal 6, new.pos

    new = DefaultScopedWhereMixin.create
    assert_equal 7, new.pos

    new4 = DefaultScopedWhereMixin.create
    assert_equal 8, new4.pos

    new4.insert_at(2)
    assert_equal 2, new4.pos

    new.reload
    assert_equal 8, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 3, new4.pos

    new5 = DefaultScopedWhereMixin.create
    assert_equal 9, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 4, new4.pos
  end

  def test_update_position
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)
    DefaultScopedWhereMixin.where(:active => false).find(2).set_list_position(4)
    assert_equal [1, 3, 4, 2], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)
    DefaultScopedWhereMixin.where(:active => false).find(2).set_list_position(2)
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)
    DefaultScopedWhereMixin.where(:active => false).find(1).set_list_position(4)
    assert_equal [2, 3, 4, 1], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)
    DefaultScopedWhereMixin.where(:active => false).find(1).set_list_position(1)
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.where(:active => false).find(:all).map(&:id)
  end

end

class MultiDestroyTest < ActsAsListTestCase

  def setup
    setup_db
  end

  # example:
  #
  #   class TodoList < ActiveRecord::Base
  #     has_many :todo_items, :order => "position"
  #     accepts_nested_attributes_for :todo_items, :allow_destroy => true
  #   end
  #
  #   class TodoItem < ActiveRecord::Base
  #     belongs_to :todo_list
  #     acts_as_list :scope => :todo_list
  #   end
  #
  # Assume that there are three items.
  # The user mark two items as deleted, click save button, form will be post:
  #
  # todo_list.todo_items_attributes = [
  #   {id: 1, _destroy: true},
  #   {id: 2, _destroy: true}
  # ]
  #
  # Save toto_list, the position of item #3 should eql 1.
  #
  def test_destroy
    new1 = DefaultScopedMixin.create
    assert_equal 1, new1.pos

    new2 = DefaultScopedMixin.create
    assert_equal 2, new2.pos

    new3 = DefaultScopedMixin.create
    assert_equal 3, new3.pos

    new1.destroy
    new2.destroy
    new3.reload
    assert_equal 1, new3.pos
  end
end

#class TopAdditionMixin < Mixin

class TopAdditionTest < ActsAsListTestCase
  include Shared::TopAddition

  def setup
    setup_db
    super
  end
end


class TopAdditionTestWithDefault < ActsAsListTestCase
  include Shared::TopAddition

  def setup
    setup_db_with_default
    super
  end
end

class RespectMixinProtection < ActsAsListTestCase
  def setup
    setup_db_with_default
    super
  end

  # if an attribute is set attr_protected
  # it should be unchanged by update_attributes
  def test_unmodified_protection
    a = ProtectedMixin.new
    a.update_attributes({:active => false})
    assert_equal true, a.active
  end

  # even after the acts_as_list mixin is joined
  # that protection should continue to exist
  def test_still_protected
    b = ProtectedListMixin.new
    b.update_attributes({:active => false})
    assert_equal true, b.active
  end

  # similarly, if a class lacks mass_assignment protection
  # it should be able to be changed
  def test_unprotected
    a = UnProtectedMixin.new
    a.update_attributes({:active => false})
    assert_equal false, a.active
  end

  # and it should continue to be mutable by mass_assignment
  # even after the acts_as_list plugin has been joined
  def test_still_unprotected_mixin
    b = UnProtectedListMixin.new
    b.assign_attributes({:active => false})
    # p UnProtectedListMixin.accessible_attributes.length
    assert_equal false, b.active
  end

end
