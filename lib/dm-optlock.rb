require 'rubygems'

gem 'dm-core', '=0.9.5'
require 'dm-core'

module DataMapper
  # Raised when the row represented by the object which is to be saved was updated in meantime.
  class StaleObjectError < StandardError
  end
  
  # Enables optimistic row locking in DM.
  module OptLock
    DEFAULT_LOCKING_COLUMN = :lock_version
   
    # hmm...
    def self.included(base)
      base.extend ClassMethods
      base.before :save, :check_lock_version
    end

    private
    # Checks if the row has been changed since being loaded from the database.
    def check_lock_version
      if self.respond_to?(self.class.locking_column.to_s) && !self.new_record? && self.dirty?
        id = self.id
        id = self.original_values[:id] if self.original_values.include?(:id)
        if self.original_values.include?(self.class.locking_column) || self.class.first(:id => id, self.class.locking_column => self.attributes[self.class.locking_column]).nil?
          raise DataMapper::StaleObjectError
        else
          self.attributes = {self.class.locking_column => self.attributes[self.class.locking_column] + 1}
        end
      end
    end
    
    module ClassMethods
        
        @@lock_column = nil
        
        # Set the column to use for optimistic locking. Defaults to lock_version.
        def set_locking_column(name = nil)
          @@lock_column = name
        end

        # The version column used for optimistic locking. Defaults to lock_version.
        def locking_column
          return DEFAULT_LOCKING_COLUMN unless @@lock_column
          return @@lock_column
        end
    end
  end

  Resource::append_inclusions OptLock
end
