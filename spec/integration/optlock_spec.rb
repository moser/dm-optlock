require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  describe 'DataMapper::OptLock' do
    before :all do
      class Thing
        include DataMapper::Resource
        property :id, Integer, :serial => true
        property :name, String
        property :row_version, Integer, :default => 0
        
        set_locking_column :row_version

        auto_migrate!(:default)
      end
    end

    after do
     repository(:default).adapter.execute('DELETE from things');
    end

    it "shouldn't save second" do
      t = Thing.new(:name => 'Banana')
      t.save
      tA = Thing.first
      tB = Thing.first
      tA.name = 'Apple'
      tB.name = 'Pineapple'
      tA.save.should be_true
      lambda { tB.save.should }.should raise_error(DataMapper::StaleObjectError)
    end

  end
end
