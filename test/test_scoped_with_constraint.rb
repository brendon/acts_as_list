# frozen_string_literal: true
require 'helper'

class TestScopedWithConstraint < ActiveRecord::Base
  belongs_to :scoped_parent, class_name: "ScopedParentClass", foreign_key: "scoped_parent_id"

  acts_as_list scope: :scoped_parent
end

class ScopedParentClass < ActiveRecord::Base
  self.table_name = "scoped_parents"
  has_many :test_scoped_with_constraints, -> { order(position: :asc) }, foreign_key: 'scoped_parent_id', dependent: :destroy
  accepts_nested_attributes_for :test_scoped_with_constraints, allow_destroy: true
end

class ScopedWithUserDefinedUniqueConstraint < Minitest::Test
  def setup
    ActiveRecord::Base.connection.create_table :scoped_parents do |t|
      t.column :name, :string
    end
    ActiveRecord::Base.connection.create_table :test_scoped_with_constraints do |t|
      t.column :scoped_parent_id, :integer
      t.column :position, :integer
    end

    # Add unique constraint to scoped_parent_id and position columns
    ActiveRecord::Base.connection.execute "ALTER TABLE test_scoped_with_constraints ADD CONSTRAINT scoped_parent_id_position_unique UNIQUE (scoped_parent_id, position)"
    ActiveRecord::Base.connection.schema_cache.clear!
    [ScopedParentClass, TestScopedWithConstraint].each(&:reset_column_information)
    super
  end

  def teardown
    teardown_db
    super
  end

  def test_scope_with_nested_attributes_repositioning
    test_scope_with_constraints_attributes = [
      { position: 1 }, { position: 2 }, { position: 3 }
    ]
    scoped_parent = ScopedParentClass.create(name: "Test", test_scoped_with_constraints_attributes: test_scope_with_constraints_attributes)
    position1_test_instance = scoped_parent.test_scoped_with_constraints.find_by(position: 1)
    position2_test_instance = scoped_parent.test_scoped_with_constraints.find_by(position: 2)
    position3_test_instance = scoped_parent.test_scoped_with_constraints.find_by(position: 3)

    test_scope_with_constraints_attributes = [
      { id: position1_test_instance.id, position: 4 }, { id: position2_test_instance.id, position: 5 }, { id: position3_test_instance.id, position: 6 }
    ]

    scoped_parent.update(test_scoped_with_constraints_attributes: test_scope_with_constraints_attributes)

    scoped_parent.reload
    assert_equal 1, position1_test_instance.reload.position
    assert_equal 2, position2_test_instance.reload.position
    assert_equal 3, position3_test_instance.reload.position
  end

  def test_scope_with_user_defined_unique_constraint
    test_scope_with_constraints_attributes = [
      { position: 1 }, { position: 2 }, { position: 3 }
    ]
    scoped_parent = ScopedParentClass.create(name: "Test", test_scoped_with_constraints_attributes: test_scope_with_constraints_attributes)
    position1_test_instance = scoped_parent.test_scoped_with_constraints.find_by(position: 1)
    position2_test_instance = scoped_parent.test_scoped_with_constraints.find_by(position: 2)
    position3_test_instance = scoped_parent.test_scoped_with_constraints.find_by(position: 3)

    test_scope_with_constraints_attributes = [
      { id: position1_test_instance.id, position: 2 }, { id: position2_test_instance.id, position: 3 }, { id: position3_test_instance.id, position: 1 }
    ]

    scoped_parent.update(test_scoped_with_constraints_attributes: test_scope_with_constraints_attributes)

    scoped_parent.reload
    assert_equal 2, position1_test_instance.reload.position
    assert_equal 3, position2_test_instance.reload.position
    assert_equal 1, position3_test_instance.reload.position
  end
end
