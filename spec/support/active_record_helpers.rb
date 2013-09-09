module ActiveRecordHelpers

  def rails3?
    defined?(ActiveRecord::VERSION) && ActiveRecord::VERSION::MAJOR >= 3
  end

  def rails4?
    defined?(ActiveRecord::VERSION) && ActiveRecord::VERSION::MAJOR >= 4
  end
end