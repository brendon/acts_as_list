# NOTE: following now done in helper.rb (better Readability)
require 'helper'

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Schema.verbose = false

def setup_db(position_options = {})
  # AR caches columns options like defaults etc. Clear them!
  ActiveRecord::Base.connection.create_table :mixins do |t|
    t.column :pos, :integer, position_options
    t.column :active, :boolean, default: true
    t.column :parent_id, :integer
    t.column :parent_type, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
    t.column :state, :integer
  end

  mixins = [ Mixin, ListMixin, ListMixinSub1, ListMixinSub2, ListWithStringScopeMixin,
    ArrayScopeListMixin, ZeroBasedMixin, DefaultScopedMixin,
    DefaultScopedWhereMixin, TopAdditionMixin, NoAdditionMixin ]

  mixins << EnumArrayScopeListMixin if rails_4

  ActiveRecord::Base.connection.schema_cache.clear!
  mixins.each do |klass|
    klass.reset_column_information
  end
end

def setup_db_with_default
  setup_db default: 0
end

# Returns true if ActiveRecord is rails3,4 version
def rails_3
  defined?(ActiveRecord::VERSION) && ActiveRecord::VERSION::MAJOR >= 3
end

def rails_4
  defined?(ActiveRecord::VERSION) && ActiveRecord::VERSION::MAJOR >= 4
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
  self.table_name = 'mixins'
end

class ListMixin < Mixin
  acts_as_list column: "pos", scope: :parent
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
  if rails_3
    validates :pos, presence: true
  else
    validates_presence_of :pos
  end
end

class ListWithStringScopeMixin < Mixin
  acts_as_list column: "pos", scope: 'parent_id = #{parent_id}'
end

class ArrayScopeListMixin < Mixin
  acts_as_list column: "pos", scope: [:parent_id, :parent_type]
end

if rails_4
  class EnumArrayScopeListMixin < Mixin
    STATE_VALUES = %w(active archived)
    enum state: STATE_VALUES

    acts_as_list column: "pos", scope: [:parent_id, :state]
  end
end

class ZeroBasedMixin < Mixin
  acts_as_list column: "pos", top_of_list: 0, scope: [:parent_id]
end

class DefaultScopedMixin < Mixin
  acts_as_list column: "pos"
  default_scope { order('pos ASC') }
end

class DefaultScopedWhereMixin < Mixin
  acts_as_list column: "pos"
  default_scope { order('pos ASC').where(active: true) }

  def self.for_active_false_tests
    unscoped.order('pos ASC').where(active: false)
  end
end

class TopAdditionMixin < Mixin
  acts_as_list column: "pos", add_new_at: :top, scope: :parent_id
end

class NoAdditionMixin < Mixin
  acts_as_list column: "pos", add_new_at: nil, scope: :parent_id
end

class TheAbstractClass < ActiveRecord::Base
  self.abstract_class = true
  self.table_name = 'mixins'
end

class TheAbstractSubclass < TheAbstractClass
  acts_as_list column: "pos", scope: :parent
end

class TheBaseClass < ActiveRecord::Base
  self.table_name = 'mixins'
  acts_as_list column: "pos", scope: :parent
end

class TheBaseSubclass < TheBaseClass
end

class ActsAsListTestCase < Minitest::Test
  # No default test required as this class is abstract.
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
    (1..4).each { |counter| DefaultScopedMixin.create!({pos: counter}) }
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
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 2).first.move_lower
    assert_equal [1, 3, 2, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 2).first.move_higher
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 1).first.move_to_bottom
    assert_equal [2, 3, 4, 1], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 1).first.move_to_top
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 2).first.move_to_bottom
    assert_equal [1, 3, 4, 2], DefaultScopedMixin.all.map(&:id)

    DefaultScopedMixin.where(id: 4).first.move_to_top
    assert_equal [4, 1, 3, 2], DefaultScopedMixin.all.map(&:id)
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
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 2).first.set_list_position(4)
    assert_equal [1, 3, 4, 2], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 2).first.set_list_position(2)
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 1).first.set_list_position(4)
    assert_equal [2, 3, 4, 1], DefaultScopedMixin.all.map(&:id)
    DefaultScopedMixin.where(id: 1).first.set_list_position(1)
    assert_equal [1, 2, 3, 4], DefaultScopedMixin.all.map(&:id)
  end
end

class DefaultScopedWhereTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| DefaultScopedWhereMixin.create! pos: counter, active: false }
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
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.move_lower
    assert_equal [1, 3, 2, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.move_higher
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.move_to_bottom
    assert_equal [2, 3, 4, 1], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.move_to_top
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.move_to_bottom
    assert_equal [1, 3, 4, 2], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)

    DefaultScopedWhereMixin.for_active_false_tests.where(id: 4).first.move_to_top
    assert_equal [4, 1, 3, 2], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
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
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.set_list_position(4)
    assert_equal [1, 3, 4, 2], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 2).first.set_list_position(2)
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.set_list_position(4)
    assert_equal [2, 3, 4, 1], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
    DefaultScopedWhereMixin.for_active_false_tests.where(id: 1).first.set_list_position(1)
    assert_equal [1, 2, 3, 4], DefaultScopedWhereMixin.for_active_false_tests.map(&:id)
  end

end

class MultiDestroyTest < ActsAsListTestCase

  def setup
    setup_db
  end

  # example:
  #
  #   class TodoList < ActiveRecord::Base
  #     has_many :todo_items, order: "position"
  #     accepts_nested_attributes_for :todo_items, allow_destroy: true
  #   end
  #
  #   class TodoItem < ActiveRecord::Base
  #     belongs_to :todo_list
  #     acts_as_list scope: :todo_list
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

class NoAdditionTest < ActsAsListTestCase
  include Shared::NoAddition

  def setup
    setup_db
    super
  end
end

class MultipleListsTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 1}
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 2}
  end

  def test_check_scope_order
    assert_equal [1, 2, 3, 4], ListMixin.where(:parent_id => 1).order(:pos).map(&:id)
    assert_equal [5, 6, 7, 8], ListMixin.where(:parent_id => 2).order(:pos).map(&:id)
    ListMixin.find(4).update_attributes(:parent_id => 2, :pos => 2)
    assert_equal [1, 2, 3], ListMixin.where(:parent_id => 1).order(:pos).map(&:id)
    assert_equal [5, 4, 6, 7, 8], ListMixin.where(:parent_id => 2).order(:pos).map(&:id)
  end

  def test_check_scope_position
    assert_equal [1, 2, 3, 4], ListMixin.where(:parent_id => 1).map(&:pos)
    assert_equal [1, 2, 3, 4], ListMixin.where(:parent_id => 2).map(&:pos)
    ListMixin.find(4).update_attributes(:parent_id => 2, :pos => 2)
    assert_equal [1, 2, 3], ListMixin.where(:parent_id => 1).order(:pos).map(&:pos)
    assert_equal [1, 2, 3, 4, 5], ListMixin.where(:parent_id => 2).order(:pos).map(&:pos)
  end
end

if rails_4
  class EnumArrayScopeListMixinTest < ActsAsListTestCase
    def setup
      setup_db
      EnumArrayScopeListMixin.create! :parent_id => 1, :state => EnumArrayScopeListMixin.states['active']
      EnumArrayScopeListMixin.create! :parent_id => 1, :state => EnumArrayScopeListMixin.states['archived']
      EnumArrayScopeListMixin.create! :parent_id => 2, :state => EnumArrayScopeListMixin.states["active"]
      EnumArrayScopeListMixin.create! :parent_id => 2, :state => EnumArrayScopeListMixin.states["archived"]
    end

    def test_positions
      assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 1, :state => EnumArrayScopeListMixin.states['active']).map(&:pos)
      assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 1, :state => EnumArrayScopeListMixin.states['archived']).map(&:pos)
      assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 2, :state => EnumArrayScopeListMixin.states['active']).map(&:pos)
      assert_equal [1], EnumArrayScopeListMixin.where(:parent_id => 2, :state => EnumArrayScopeListMixin.states['archived']).map(&:pos)
    end
  end
end

class MultipleListsArrayScopeTest < ActsAsListTestCase
  def setup
    setup_db
    (1..4).each { |counter| ArrayScopeListMixin.create! :pos => counter,:parent_id => 1, :parent_type => 'anything'}
    (1..4).each { |counter| ArrayScopeListMixin.create! :pos => counter,:parent_id => 2, :parent_type => 'something'}
    (1..4).each { |counter| ArrayScopeListMixin.create! :pos => counter,:parent_id => 3, :parent_type => 'anything'}
  end

  def test_order_after_all_scope_properties_are_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order(:pos).map(&:id)
    assert_equal [5, 6, 7, 8], ArrayScopeListMixin.where(:parent_id => 2, :parent_type => 'something').order(:pos).map(&:id)
    ArrayScopeListMixin.find(2).update_attributes(:parent_id => 2, :pos => 2,:parent_type => 'something')
    assert_equal [1, 3, 4], ArrayScopeListMixin.where(:parent_id => 1,:parent_type => 'anything').order(:pos).map(&:id)
    assert_equal [5, 2, 6, 7, 8], ArrayScopeListMixin.where(:parent_id => 2,:parent_type => 'something').order(:pos).map(&:id)
  end

  def test_position_after_all_scope_properties_are_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').map(&:pos)
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 2, :parent_type => 'something').map(&:pos)
    ArrayScopeListMixin.find(4).update_attributes(:parent_id => 2, :pos => 2, :parent_type => 'something')
    assert_equal [1, 2, 3], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order(:pos).map(&:pos)
    assert_equal [1, 2, 3, 4, 5], ArrayScopeListMixin.where(:parent_id => 2, :parent_type => 'something').order(:pos).map(&:pos)
  end

  def test_order_after_one_scope_property_is_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order(:pos).map(&:id)
    assert_equal [9, 10, 11, 12], ArrayScopeListMixin.where(:parent_id => 3, :parent_type => 'anything').order(:pos).map(&:id)
    ArrayScopeListMixin.find(2).update_attributes(:parent_id => 3, :pos => 2)
    assert_equal [1, 3, 4], ArrayScopeListMixin.where(:parent_id => 1,:parent_type => 'anything').order(:pos).map(&:id)
    assert_equal [9, 2, 10, 11, 12], ArrayScopeListMixin.where(:parent_id => 3,:parent_type => 'anything').order(:pos).map(&:id)
  end

  def test_position_after_one_scope_property_is_changed
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').map(&:pos)
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 3, :parent_type => 'anything').map(&:pos)
    ArrayScopeListMixin.find(4).update_attributes(:parent_id => 3, :pos => 2)
    assert_equal [1, 2, 3], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order(:pos).map(&:pos)
    assert_equal [1, 2, 3, 4, 5], ArrayScopeListMixin.where(:parent_id => 3, :parent_type => 'anything').order(:pos).map(&:pos)
  end

  def test_order_after_moving_to_empty_list
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order(:pos).map(&:id)
    assert_equal [], ArrayScopeListMixin.where(:parent_id => 4, :parent_type => 'anything').order(:pos).map(&:id)
    ArrayScopeListMixin.find(2).update_attributes(:parent_id => 4, :pos => 1)
    assert_equal [1, 3, 4], ArrayScopeListMixin.where(:parent_id => 1,:parent_type => 'anything').order(:pos).map(&:id)
    assert_equal [2], ArrayScopeListMixin.where(:parent_id => 4,:parent_type => 'anything').order(:pos).map(&:id)
  end

  def test_position_after_moving_to_empty_list
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').map(&:pos)
    assert_equal [], ArrayScopeListMixin.where(:parent_id => 4, :parent_type => 'anything').map(&:pos)
    ArrayScopeListMixin.find(2).update_attributes(:parent_id => 4, :pos => 1)
    assert_equal [1, 2, 3], ArrayScopeListMixin.where(:parent_id => 1, :parent_type => 'anything').order(:pos).map(&:pos)
    assert_equal [1], ArrayScopeListMixin.where(:parent_id => 4, :parent_type => 'anything').order(:pos).map(&:pos)
  end
end
