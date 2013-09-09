require 'spec_helper'

# These are the minimum set of examples for any list
shared_examples 'an ordered list' do

  # shared example context override when needed
  let(:position_column) { :position }
  let(:primary_key) { :id }
  # Default list, invoke create! with numbered position and return
  # the whole collection as unordered list
  let(:list) do
    1.upto(4) { |position| described_class.create!(position_column => position) }
    rails4? ? described_class.all : described_class.scoped
  end

  # Return records in order given by position column
  def ordered_list
    list.reorder(position_column)
  end

  # Return primary keys in order given by position column
  def ordered_ids
    ordered_list.pluck(primary_key)
  end

  # used as precondition for other specs
  before { list.should have(4).elements }

  describe '#move_lower' do

    it 'should move a generic element' do
      second_element = ordered_list.second
      expect {
        second_element.move_lower
      }.to change { ordered_list.third }.to(second_element)
    end

    it 'should not touch last element' do
      last_element = ordered_list.last
      expect { last_element.move_lower }.to_not change { ordered_ids }
      last_element.should have_position(list.size).in_list(ordered_list)
    end

  end

  describe '#move_to_bottom' do

    it 'should move a generic element' do
      second_element = ordered_list.second
      expect {
        second_element.move_to_bottom
      }.to change { ordered_list.last }.to(second_element)
    end

    it 'should not touch last element' do
      last_element = ordered_list.last
      expect { last_element.move_to_bottom }.to_not change { ordered_ids }
      last_element.should have_position(list.size).in_list(ordered_list)
    end

  end

  describe '#move_higher' do

    it 'should move a generic element' do
      second_element = ordered_list.second
      expect {
        second_element.move_higher
      }.to change { ordered_list.first }.to(second_element)
    end

    it 'should not touch first element' do
      first_element = ordered_list.first
      expect { first_element.move_higher }.to_not change { ordered_ids }
      first_element.should have_position(1).in_list(ordered_list)
    end

  end

  describe '#move_to_top' do

    it 'should move a generic element' do
      third_element = ordered_list.third
      expect {
        third_element.move_to_top
      }.to change { ordered_list.first }.to(third_element)
    end

    it 'should not touch first element' do
      first_element = ordered_list.first
      expect { first_element.move_higher }.to_not change { ordered_ids }
      first_element.should have_position(1).in_list(ordered_list)
    end
  end

  describe '#first?' do

    it 'should be true only for first element' do
      ordered_list.first.should be_first
      ordered_list.drop(1).each do |element|
        element.should_not be_first
      end
    end

  end

  describe '#last?' do

    it 'should be true only for last element' do
      ordered_list.last.should be_last
      ordered_list.reverse.drop(1).each do |element|
        element.should_not be_last
      end
    end

  end

  describe '#insert_at' do

    it 'should correctly insert at top of list' do
      last_element = ordered_list.last
      last_element.insert_at # default arg is acts_as_list_top
      last_element.should have_position(1).in_list(ordered_list)
    end

    it 'should correctly insert at bottom of list' do
      second_element = ordered_list.second
      second_element.insert_at(ordered_list.size)
      second_element.should have_position(ordered_list.size).in_list(ordered_list)
    end

    it 'should correctly insert in the middle of the list' do
      first_element = ordered_list.first
      first_element.insert_at(2)
      first_element.should have_position(2).in_list(ordered_list)
    end

  end

end
