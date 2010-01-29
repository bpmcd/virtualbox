require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class RelatableTest < Test::Unit::TestCase
  class Relatee
    def self.populate_relationship(caller, data)
      "FOO"
    end
  end
  class BarRelatee
    def self.set_relationship(caller, old_value, new_value)
    end
  end
  
  class RelatableModel
    include VirtualBox::AbstractModel::Relatable
    
    relationship :foos, Relatee
    relationship :bars, BarRelatee
  end
  
  setup do
    @data = {}
  end
  
  context "setting a relationship" do
    setup do
      @model = RelatableModel.new
    end
    
    should "have a magic method relationship= which calls set_relationship" do
      @model.expects(:set_relationship).with(:foos, "FOOS!")
      @model.foos = "FOOS!"
    end
    
    should "raise a NonSettableRelationshipException if relationship can't be set" do
      assert_raises(VirtualBox::Exceptions::NonSettableRelationshipException) {
        @model.foos = "FOOS!"
      }
    end
    
    should "call set_relationship on the relationship class" do
      BarRelatee.expects(:populate_relationship).returns("foo")
      @model.populate_relationships({})
      
      BarRelatee.expects(:set_relationship).with(@model, "foo", "bars")
      assert_nothing_raised { @model.bars = "bars" }
    end
    
    should "set the result of set_relationship as the new relationship data" do
      BarRelatee.stubs(:set_relationship).returns("hello")
      @model.bars = "zoo"
      assert_equal "hello", @model.bars
    end
  end
  
  context "subclasses" do
    class SubRelatableModel < RelatableModel
      relationship :bars, RelatableTest::Relatee
    end
    
    setup do
      @relationships = SubRelatableModel.relationships
    end
    
    should "inherit relationships of parent" do
      assert @relationships.has_key?(:foos)
      assert @relationships.has_key?(:bars)
    end
    
    should "inherit options of relationships" do
      assert_equal Relatee, @relationships[:foos][:klass]
    end
  end
  
  context "default callbacks" do
    setup do
      @model = RelatableModel.new
    end
    
    should "not raise an error if populate_relationship doesn't exist" do
      assert !BarRelatee.respond_to?(:populate_relationship)
      assert_nothing_raised { @model.populate_relationships(nil) }
    end
    
    should "not raise an error when saving relationships if the callback doesn't exist" do
      assert !Relatee.respond_to?(:save_relationship)
      assert_nothing_raised { @model.save_relationships }
    end
    
    should "not raise an error in destroying relationships if the callback doesn't exist" do
      assert !Relatee.respond_to?(:destroy_relationship)
      assert_nothing_raised { @model.destroy_relationships }
    end
  end
  
  context "destroying" do
    setup do
      @model = RelatableModel.new
      @model.populate_relationships({})
    end
    
    context "a single relationship" do
      should "call destroy_relationship only for the given relationship" do
        Relatee.expects(:destroy_relationship).once
        BarRelatee.expects(:destroy_relationship).never
        @model.destroy_relationship(:foos)
      end
      
      should "forward any args passed into destroy_relationship" do
        Relatee.expects(:destroy_relationship).with(@model, anything, "HELLO").once
        @model.destroy_relationship(:foos, "HELLO")
      end
      
      should "pass the data into destroy_relationship" do
        Relatee.expects(:destroy_relationship).with(@model, "FOO").once
        @model.destroy_relationship(:foos)
      end
    end

    context "all relationships" do
      should "call destroy_relationship on the related class" do
        Relatee.expects(:destroy_relationship).with(@model, anything).once
        @model.destroy_relationships
      end
    
      should "forward any args passed into destroy relationships" do
        Relatee.expects(:destroy_relationship).with(@model, anything, "HELLO").once
        @model.destroy_relationships("HELLO")
      end
    end
  end
  
  context "saving relationships" do
    setup do
      @model = RelatableModel.new
    end
    
    should "call save_relationship on the related class" do
      Relatee.expects(:save_relationship).with(@model, @model.foos).once
      @model.save_relationships
    end
    
    should "forward parameters through" do
      Relatee.expects(:save_relationship).with(@model, @model.foos, "YES").once
      @model.save_relationships("YES")
    end
  end
  
  context "reading relationships" do
    setup do
      @model = RelatableModel.new
    end
    
    should "provide a read method for relationships" do
      assert_nothing_raised { @model.foos }
    end
  end
  
  context "checking for relationships" do
    setup do
      @model = RelatableModel.new
    end
    
    should "return true for existing relationships" do
      assert @model.has_relationship?(:foos)
    end
    
    should "return false for nonexistent relationships" do
      assert !@model.has_relationship?(:bazs)
    end
  end
  
  context "populating relationships" do
    setup do
      @model = RelatableModel.new
    end
    
    should "call populate_relationship on the related class" do
      Relatee.expects(:populate_relationship).with(@model, @data).once
      @model.populate_relationships(@data)
    end
    
    should "properly save returned value as the value for the relationship" do
      Relatee.expects(:populate_relationship).once.returns("HEY")
      @model.populate_relationships(@data)
      assert_equal "HEY", @model.foos
    end
  end
end