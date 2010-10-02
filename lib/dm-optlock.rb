$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
  
require 'rubygems'
gem 'dm-core', '>=0.9.5'
require 'dm-core'

module DataMapper
  class StaleObjectError < StandardError
  end
  
  module DmOptlock
    VERSION = '0.1.4'
    DEFAULT_LOCKING_COLUMN = :lock_version
   
    def self.included(base) #:nodoc:
      base.extend ClassMethods
      base.before :save, :check_lock_version
    end

    private
    # Checks if the row has been changed since being loaded from the database.
    def check_lock_version
      if !new_record? && dirty? && respond_to?(self.class.locking_column.to_s)
        if original_values.include?(:id)
          row = self.class.get(original_values[:id]) 
        else
          row = self.class.get(id)
        end
        if !row.nil? && row.attribute_get(self.class.locking_column) != attribute_get(self.class.locking_column)
          attributes = original_values
          raise DataMapper::StaleObjectError
        else
          attribute_set(self.class.locking_column, attribute_get(self.class.locking_column) + 1)
        end
      end
    end
    
    module ClassMethods
        @@lock_column = nil
        
        # Set the column to use for optimistic locking. Defaults to lock_version.
        def add_locking_column(name = DEFAULT_LOCKING_COLUMN, options = {})
          options.merge!({:default => 0, :writer => :protected})
          @@lock_column = name
          property name, Integer, options
        end

        # The version column used for optimistic locking. Defaults to lock_version.
        def locking_column
          return @@lock_column
        end
    end
  end
  
  Model::append_inclusions DmOptlock
end
