require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 1.15.4.7794'
require 'active_record'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :pos, :integer
      t.column :parent_id, :integer
      t.column :parent_type, :string
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class ListMixin < Mixin
  acts_as_list :column => "pos", :scope => :parent

  def self.table_name() "mixins" end
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
end

class ListWithStringScopeMixin < ActiveRecord::Base
  acts_as_list :column => "pos", :scope => 'parent_id = #{parent_id}'

  def self.table_name() "mixins" end
end

class ArrayScopeListMixin < Mixin
  acts_as_list :column => "pos", :scope => [:parent_id, :parent_type]

  def self.table_name() "mixins" end
end

class ListTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 5 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
    assert_nil ListMixin.find(1).higher_item
    assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
    assert_nil ListMixin.find(4).lower_item
  end

  def test_injection
    item = ListMixin.new(:parent_id => 1)
    assert_equal '"mixins"."parent_id" = 1', item.scope_condition
    assert_equal "pos", item.position_column
  end

  def test_insert
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 0)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_insert_at
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create(:parent_id => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixin.create(:parent_id => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

  def test_with_string_based_scope
    new = ListWithStringScopeMixin.create(:parent_id => 500)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_nil_scope
    new1, new2, new3 = ListMixin.create, ListMixin.create, ListMixin.create
    new2.move_higher
    assert_equal [new2, new1, new3], ListMixin.find(:all, :conditions => 'parent_id IS NULL', :order => 'pos')
  end

  def test_remove_from_list_should_then_fail_in_list? 
    assert_equal true, ListMixin.find(1).in_list?
    ListMixin.find(1).remove_from_list
    assert_equal false, ListMixin.find(1).in_list?
  end 
  
  def test_remove_from_list_should_set_position_to_nil 
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    ListMixin.find(2).remove_from_list 
  
    assert_equal [2, 1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    assert_equal 1,   ListMixin.find(1).pos
    assert_equal nil, ListMixin.find(2).pos
    assert_equal 2,   ListMixin.find(3).pos
    assert_equal 3,   ListMixin.find(4).pos
  end 
  
  def test_remove_before_destroy_does_not_shift_lower_items_twice 
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    ListMixin.find(2).remove_from_list 
    ListMixin.find(2).destroy 
  
    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)
  
    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos
  end 
  
  def test_before_destroy_callbacks_do_not_update_position_to_nil_before_deleting_the_record
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    # We need to trigger all the before_destroy callbacks without actually
    # destroying the record so we can see the affect the callbacks have on
    # the record.
    list = ListMixin.find(2)
    if list.respond_to?(:run_callbacks)
      list.run_callbacks(:destroy)
    else
      list.send(:callback, :before_destroy)
    end

    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(2).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos
  end

end

class ListSubTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |i| ((i % 2 == 1) ? ListMixinSub1 : ListMixinSub2).create! :pos => i, :parent_id => 5000 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ListMixin.find(2), ListMixin.find(1).lower_item
    assert_nil ListMixin.find(1).higher_item
    assert_equal ListMixin.find(3), ListMixin.find(4).higher_item
    assert_nil ListMixin.find(4).lower_item
  end

  def test_injection
    item = ListMixin.new("parent_id"=>1)
    assert_equal '"mixins"."parent_id" = 1', item.scope_condition
    assert_equal "pos", item.position_column
  end

  def test_insert_at
    new = ListMixin.create("parent_id" => 20)
    assert_equal 1, new.pos

    new = ListMixinSub1.create("parent_id" => 20)
    assert_equal 2, new.pos

    new = ListMixinSub2.create("parent_id" => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create("parent_id" => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixinSub1.create("parent_id" => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.find(:all, :conditions => 'parent_id = 5000', :order => 'pos').map(&:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

end

class ArrayScopeListTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |counter| ArrayScopeListMixin.create! :pos => counter, :parent_id => 5, :parent_type => 'ParentClass' }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    ArrayScopeListMixin.find(2).move_lower
    assert_equal [1, 3, 2, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    ArrayScopeListMixin.find(2).move_higher
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    ArrayScopeListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    ArrayScopeListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    ArrayScopeListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    ArrayScopeListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)
    ArrayScopeListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)
  end

  def test_next_prev
    assert_equal ArrayScopeListMixin.find(2), ArrayScopeListMixin.find(1).lower_item
    assert_nil ArrayScopeListMixin.find(1).higher_item
    assert_equal ArrayScopeListMixin.find(3), ArrayScopeListMixin.find(4).higher_item
    assert_nil ArrayScopeListMixin.find(4).lower_item
  end

  def test_injection
    item = ArrayScopeListMixin.new(:parent_id => 1, :parent_type => 'ParentClass')
    assert_equal '"mixins"."parent_id" = 1 AND "mixins"."parent_type" = \'ParentClass\'', item.scope_condition
    assert_equal "pos", item.position_column
  end

  def test_insert
    new = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = ArrayScopeListMixin.create(:parent_id => 0, :parent_type => 'ParentClass')
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_insert_at
    new = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 1, new.pos

    new = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 2, new.pos

    new = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 3, new.pos

    new4 = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ArrayScopeListMixin.create(:parent_id => 20, :parent_type => 'ParentClass')
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    ArrayScopeListMixin.find(2).destroy

    assert_equal [1, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    assert_equal 1, ArrayScopeListMixin.find(1).pos
    assert_equal 2, ArrayScopeListMixin.find(3).pos
    assert_equal 3, ArrayScopeListMixin.find(4).pos

    ArrayScopeListMixin.find(1).destroy

    assert_equal [3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)

    assert_equal 1, ArrayScopeListMixin.find(3).pos
    assert_equal 2, ArrayScopeListMixin.find(4).pos
  end
  
  def test_remove_from_list_should_then_fail_in_list? 
    assert_equal true, ArrayScopeListMixin.find(1).in_list?
    ArrayScopeListMixin.find(1).remove_from_list
    assert_equal false, ArrayScopeListMixin.find(1).in_list?
  end 
  
  def test_remove_from_list_should_set_position_to_nil 
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)
  
    ArrayScopeListMixin.find(2).remove_from_list 
  
    assert_equal [2, 1, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)
  
    assert_equal 1,   ArrayScopeListMixin.find(1).pos
    assert_equal nil, ArrayScopeListMixin.find(2).pos
    assert_equal 2,   ArrayScopeListMixin.find(3).pos
    assert_equal 3,   ArrayScopeListMixin.find(4).pos
  end 
  
  def test_remove_before_destroy_does_not_shift_lower_items_twice 
    assert_equal [1, 2, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)
  
    ArrayScopeListMixin.find(2).remove_from_list 
    ArrayScopeListMixin.find(2).destroy 
  
    assert_equal [1, 3, 4], ArrayScopeListMixin.find(:all, :conditions => "parent_id = 5 AND parent_type = 'ParentClass'", :order => 'pos').map(&:id)
  
    assert_equal 1, ArrayScopeListMixin.find(1).pos
    assert_equal 2, ArrayScopeListMixin.find(3).pos
    assert_equal 3, ArrayScopeListMixin.find(4).pos
  end 
  
end

