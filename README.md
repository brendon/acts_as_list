# ActsAsList

## Build Status
[![Build Status](https://secure.travis-ci.org/swanandp/acts_as_list.png)](https://secure.travis-ci.org/swanandp/acts_as_list)
[![Gem Version](https://badge.fury.io/rb/acts_as_list.svg)](https://badge.fury.io/rb/acts_as_list)

## Description

This `acts_as` extension provides the capabilities for sorting and reordering a number of objects in a list. The class that has this specified needs to have a `position` column defined as an integer on the mapped database table.

## 0.8.0 Upgrade Notes

There are a couple of changes of behaviour from `0.8.0` onwards:

- If you specify `add_new_at: :top`, new items will be added to the top of the list like always. But now, if you specify a position at insert time: `.create(position: 3)`, the position will be respected. In this example, the item will end up at position `3` and will move other items further down the list. Before `0.8.0` the position would be ignored and the item would still be added to the top of the list. [#220](https://github.com/swanandp/acts_as_list/pull/220)
- `acts_as_list` now copes with disparate position integers (i.e. gaps between the numbers). There has been a change in behaviour for the `higher_items` method. It now returns items with the first item in the collection being the closest item to the reference item, and the last item in the collection being the furthest from the reference item (a.k.a. the first item in the list). [#223](https://github.com/swanandp/acts_as_list/pull/223)

## Installation

In your Gemfile:

    gem 'acts_as_list'

Or, from the command line:

    gem install acts_as_list

## Example

At first, you need to add a `position` column to desired table:

    rails g migration AddPositionToTodoItem position:integer
    rake db:migrate

After that you can use `acts_as_list` method in the model:

```ruby
class TodoList < ActiveRecord::Base
  has_many :todo_items, -> { order(position: :asc) }
end

class TodoItem < ActiveRecord::Base
  belongs_to :todo_list
  acts_as_list scope: :todo_list
end

todo_list = TodoList.find(...)
todo_list.todo_items.first.move_to_bottom
todo_list.todo_items.last.move_higher
```

## Instance Methods Added To ActiveRecord Models

You'll have a number of methods added to each instance of the ActiveRecord model that to which `acts_as_list` is added.

In `acts_as_list`, "higher" means further up the list (a lower `position`), and "lower" means further down the list (a higher `position`). That can be confusing, so it might make sense to add tests that validate that you're using the right method given your context.

### Methods That Change Position and Reorder List

- `list_item.insert_at(2)`
- `list_item.move_lower` will do nothing if the item is the lowest item
- `list_item.move_higher` will do nothing if the item is the highest item
- `list_item.move_to_bottom`
- `list_item.move_to_top`
- `list_item.remove_from_list`

### Methods That Change Position Without Reordering List

- `list_item.increment_position`
- `list_item.decrement_position`
- `list_item.set_list_position(3)`

### Methods That Return Attributes of the Item's List Position
- `list_item.first?`
- `list_item.last?`
- `list_item.in_list?`
- `list_item.not_in_list?`
- `list_item.default_position?`
- `list_item.higher_item`
- `list_item.higher_items` will return all the items above `list_item` in the list (ordered by the position, ascending)
- `list_item.lower_item`
- `list_item.lower_items` will return all the items below `list_item` in the list (ordered by the position, ascending)

## Adding `acts_as_list` To An Existing Model
As it stands `acts_as_list` requires position values to be set on the model before the instance methods above will work. Adding something like the below to your migration will set the default position. Change the parameters to order if you want a different initial ordering.

```ruby
class AddPositionToTodoItem < ActiveRecord::Migration
  def change
    add_column :todo_items, :position, :integer
    TodoItem.order(:updated_at).each.with_index(1) do |todo_item, index|
      todo_item.update_column :position, index
    end
  end
end
```

If you are using the scope option things can get a bit more complicated. Let's say you have `acts_as_list scope: :todo_list`, you might instead need something like this:

```ruby
TodoList.all.each do |todo_list|
  todo_list.todo_items.order(:updated_at).each.with_index(1) do |todo_item, index|
    todo_item.update_column :position, index
  end
end
```

## Notes
All `position` queries (select, update, etc.) inside gem methods are executed without the default scope (i.e. `Model.unscoped`), this will prevent nasty issues when the default scope is different from `acts_as_list` scope.

The `position` column is set after validations are called, so you should not put a `presence` validation on the `position` column.


If you need a scope by a non-association field you should pass an array, containing field name, to a scope:
```ruby
class TodoItem < ActiveRecord::Base
  # `kind` is a plain text field (e.g. 'work', 'shopping', 'meeting'), not an association
  acts_as_list scope: [:kind]
end
```

You can also add multiple scopes in this fashion:
```ruby
class TodoItem < ActiveRecord::Base
  acts_as_list scope: [:kind, :owner_id]
end
```

Furthermore, you can optionally include a hash of fixed parameters that will be included in all queries:
```ruby
class TodoItem < ActiveRecord::Base
  acts_as_list scope: [:kind, :owner_id, deleted_at: nil]
end
```

This is useful when using this gem in conjunction with the popular [acts_as_paranoid](https://github.com/ActsAsParanoid/acts_as_paranoid) gem.

## More Options
- `column`
default: `position`. Use this option if the column name in your database is different from position.
- `top_of_list`
default: `1`. Use this option to define the top of the list. Use 0 to make the collection act more like an array in its indexing.
- `add_new_at`
default: `:bottom`. Use this option to specify whether objects get added to the `:top` or `:bottom` of the list. `nil` will result in new items not being added to the list on create, i.e, position will be kept nil after create.

## Disabling temporarily

If you need to temporarily disable `acts_as_list` during specific operations such as mass-update or imports:
```ruby
TodoItem.acts_as_list_no_update do
  perform_mass_update
end
```
In an `acts_as_list_no_update` block, all callbacks are disabled, and positions are not updated. New records will be created with
 the default value from the database. It is your responsibility to correctly manage `positions` values.

You can also pass an array of classes as an argument to disable database updates on just those classes. It can be any ActiveRecord class that has acts_as_list enabled.
```ruby
class TodoList < ActiveRecord::Base
  has_many :todo_items, -> { order(position: :asc) }
  acts_as_list
end

class TodoItem < ActiveRecord::Base
  belongs_to :todo_list
  has_many :todo_attachments, -> { order(position: :asc) }

  acts_as_list scope: :todo_list
end

class TodoAttachment < ActiveRecord::Base
  belongs_to :todo_list
  acts_as_list scope: :todo_item
end

TodoItem.acts_as_list_no_update([TodoAttachment]) do
  TodoItem.find(10).update(position: 2)
  TodoAttachment.find(10).update(position: 1)
  TodoAttachment.find(11).update(position: 2)
  TodoList.find(2).update(position: 3) # For this instance the callbacks will be called because we haven't passed the class as an argument
end
```

## Versions
Version `0.9.0` adds `acts_as_list_no_update` (https://github.com/swanandp/acts_as_list/pull/244) and compatibility with not-null and uniqueness constraints on the database (https://github.com/swanandp/acts_as_list/pull/246). These additions shouldn't break compatibility with existing implementations.

As of version `0.7.5` Rails 5 is supported.

All versions `0.1.5` onwards require Rails 3.0.x and higher.

## Workflow Status
[![WIP Issues](https://badge.waffle.io/swanandp/acts_as_list.png)](http://waffle.io/swanandp/acts_as_list)

## Roadmap

1. Sort based feature

## Contributing to `acts_as_list`

- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
- Fork the project
- Start a feature/bugfix branch
- Commit and push until you are happy with your contribution
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
- I would recommend using Rails 3.1.x and higher for testing the build before a pull request. The current test harness does not quite work with 3.0.x. The plugin itself works, but the issue lies with testing infrastructure.

## Copyright

Copyright (c) 2007 David Heinemeier Hansson, released under the MIT license
