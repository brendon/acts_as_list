require 'spec_helper'

describe ListWithInvertedPosition do

  it_should_behave_like 'an ordered list' do
    before { list.should have_a_consistent_order }

    # Ensure list manipulation doesn't break list order
    after { list.should have_a_consistent_order }
  end

end

describe ListWithInvertedPositionTopFirst do

  it_should_behave_like 'an ordered list' do
    before { list.should have_a_consistent_order }

    # Ensure list manipulation doesn't break list order
    after { list.should have_a_consistent_order }
  end

end