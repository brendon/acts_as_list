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

# Matcher for position in list
RSpec::Matchers.define :have_position do |expected|

  # simple matcher to do something like
  # element.should have_position 3
  match do |element|
    element_position = element.send(position_column(element))
    # if no list just check for element position
    if @list.nil?
      element_position == expected if @list.nil?
    else
      # if list is given convert it to array and check for element being in that position
      element_position == expected && check_position_in_list(element)
    end
  end

  # Chain option to pass also list for matcher, allows to do
  # # with simple array
  # element.should have_position(1).in_list([element])
  # # with ar scopes and/or classes
  # element.should have_position(3).in_list(Article.where(active: true))
  # element.should have_position(3).in_list(Article)
  chain :in_list do |list|
    list = list.scoped if list.is_a?(Class) # class given as list e.g. List
    @list = list
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have position ##{expected} in #{list_to_s}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have position ##{expected} in #{list_to_s}"
  end

  description do |actual|
    "have position #{actual} in #{list_to_s}"
  end

  # Get ordered list and check if element is in that position
  def check_position_in_list(element)
    if @list.is_a? Array
      @list[position_in_array(element)] == element
    else
      # apply aal scope first
      @list.order(position_column(element))[position_in_array(element)] == element
    end
  end

  # Return position column of a given element using its method defined by aal gem
  def position_column(element)
    element.position_column
  end

  # Return element index in a given array
  # if acts_as_list_top is 0 return current position else
  # element_position - acts_as_list_top
  def position_in_array(element)
    element.position - element.acts_as_list_top
  end

  # Return a string representation of a given list
  def list_to_s
    case @list
      when nil
        # no list given, i.e. called with `element.should have_postion xxx`
        'its list'
      else
        "list #{@list.to_a}"
    end
  end

end
