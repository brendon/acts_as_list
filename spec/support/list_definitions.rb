# A list with default arguments
class DefaultList < ActiveRecord::Base
  self.table_name = 'mixins'
  # default arguments for aal gem
  acts_as_list
end

class ListWithInvertedPosition < ActiveRecord::Base
  self.table_name = 'mixins'

  # use the acts as list gem with inverted position column
  acts_as_list :inverted_position => true
end

class ListWithInvertedPositionTopFirst < ActiveRecord::Base
  self.table_name = 'mixins'

  # inverted position column and new element on top
  acts_as_list :add_new_at => :top, :inverted_position => true
end
