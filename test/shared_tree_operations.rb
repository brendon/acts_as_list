module Shared
  module TreeOperations

    # Create a complete tree with the given depth and breadth
    def make_tree(depth = 2, breadth = 2, attrs = {})
      # Create the node
      TreeMixin.create!(attrs).tap do |root|
        # Create children if required by depth
        breadth.times { make_tree(depth, breadth, parent_id: root.id) } if root.depth < depth
      end
    end

    def test_binary_tree_construction
      root = make_tree
      # Check total nodes
      assert_equal (1+2+4), root.subtree.count, 'Binary tree is built with 7 nodes'
      # Checking position of root element
      assert_equal 1, root.pos, 'Root element has position 0'
      # Checking position of children
      root.children.order(:pos).each_with_index do |c, i|
        assert_equal i + 1, c.pos, "Child #{c.id} should have position #{i+1}"
        # Grandchildren positions
        c.children.order(:pos).each_with_index do |gc, i|
          assert_equal i + 1, gc.pos, "Grandchild #{gc.id} should have position #{i+1}"
        end
      end
    end

    # Issue described in #131
    def test_binary_tree_reordering
      root = make_tree
      node_to_move = root.children.last
      assert_equal 2, node_to_move.pos, "node #{node_to_move.id} should be last child according to its list"
      node_to_move.update_attributes! parent: nil
      assert_equal [1, 2], node_to_move.children.map(&:pos)
    end

    # Also described in #131
    def test_ternary_tree_reordering
      root = make_tree(2, 3) # ternary tree with two levels
      node_to_move = root.children.last
      assert_equal 3, node_to_move.pos, "node #{node_to_move.id} should be last child according to its list"
      node_to_move.update_attributes! parent: nil
      assert_equal [1, 2, 3], node_to_move.children.map(&:pos)
    end

  end
end
