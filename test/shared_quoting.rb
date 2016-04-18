module Shared
  module Quoting

    def setup
      3.times { |counter| QuotedList.create! order: counter }
    end

    def test_create
      assert_equal QuotedList.in_list.size, 3
    end

  end
end
