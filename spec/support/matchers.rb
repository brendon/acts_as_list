RSpec::Matchers.define :have_a_consistent_order do
  # Matcher for invariant [position == -inverted_position], argument for matcher can be either
  # an AR class or a AR scope, i.e. List.should have_a_consistent_order

  match do |list_scope|
    # get position column names from scopes
    position_column = list_scope.new.position_column
    inverted_position_column = "inverted_#{position_column}"
    # get primary key name from scope
    primary_key = list_scope.primary_key
    # check that two ordering are equivalents
    list_scope.order(position_column).pluck(primary_key) ==
        list_scope.order(inverted_position_column).pluck(primary_key).reverse
  end

end

RSpec::Matchers.define :have_position do |expected|
  # Matcher for position in list

  match do |element|
    # get position column names from defined scope
    element.send(element.position_column) == expected
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have position ##{expected} in its list"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have position ##{expected} in its list"
  end

  description do |actual|
    "have position #{actual} in the list"
  end

end
