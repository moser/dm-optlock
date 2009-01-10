#:nodoc:
require 'pathname'
require Pathname(__FILE__).dirname.expand_path + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  describe 'DataMapper::DmOptlock' do
    before :all do
      class Thing
        include DataMapper::Resource
        property :id, Integer, :serial => true
        property :name, String
        
        add_locking_column :row_version

        auto_migrate!(:default)
      end
    end

    after do
     repository(:default).adapter.execute('DELETE from things');
    end

    it "shouldn't save second" do
      t = Thing.new(:name => "Banana")
      t.save
      tA = Thing.first
      tB = Thing.first
      tA.name = 'Apple'
      tB.name = 'Pineapple'
      tA.save.should be_true
      lambda { tB.save.should }.should raise_error(DataMapper::StaleObjectError)
    end
    
    it "should increment lock version" do
      t = Thing.new(:name => "Dollar")
      t.save
      t.row_version.should equal(0)
      t.name = "Euro"
      t.save
      t.row_version.should equal(1)
    end
    
    it "should be aware of ID changes" do
      t = Thing.new(:name => "abc")
      t.save
      tA = Thing.first
      tB = Thing.first
      tA.name = 'Apple'
      tB.id = 122
      tA.save.should be_true
      lambda { tB.save.should }.should raise_error(DataMapper::StaleObjectError)
    end
    
    it "'s version column should be not nullable, have default 0 and a protected writer" do
     class Foo
        include DataMapper::Resource
        property :id, Integer, :serial => true
       
        add_locking_column :foo_version, :default => 1, :nullable => false

        auto_migrate!(:default)
      end
      
      col = Foo.properties[:foo_version]
      col.nullable?.should be_false
      col.default.should be(0)
      col.writer_visibility.should equal(:protected)
    end

  end
end
