ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Schema.verbose = false

# AR caches columns options like defaults etc. Clear them!
ActiveRecord::Base.connection.schema_cache.clear!
ActiveRecord::Schema.define(:version => 1) do
  create_table :mixins do |t|
    t.column :pos, :integer, :default => 0
    t.column :active, :boolean, :default => true
    t.column :parent_id, :integer
    t.column :parent_type, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
end
