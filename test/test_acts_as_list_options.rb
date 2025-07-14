# frozen_string_literal: true

require 'helper'

class ActsAsListOptionsTest
  def setup
    setup_db
  end

  def test_acts_as_list_options_returns_the_macro_configuration # rubocop:disable Metrics/MethodLength
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'mixins'
      acts_as_list(
        column: :pos,
        scope: %i[parent_id parent_type],
        add_new_at: :top,
        top_of_list: 0,
        touch_on_update: false
      )
    end

    opts = klass.acts_as_list_options

    assert_equal %i[parent_id parent_type], opts[:scope]
    assert_equal :pos,                       opts[:column]
    assert_equal :top,                       opts[:add_new_at]
    assert_equal 0,                          opts[:top_of_list]
    assert_equal false,                      opts[:touch_on_update]
    assert_equal true,                       opts.frozen?
  end
end
