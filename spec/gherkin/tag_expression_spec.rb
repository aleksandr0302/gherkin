require 'spec_helper'
require 'gherkin/tag_expression'
require 'gherkin/formatter/model'

module Gherkin
  describe TagExpression do
    def tag(name)
      Formatter::Model::Tag.new(name, 0)
    end

    context "no tags" do
      before(:each) do
        @e = Gherkin::TagExpression.new([])
      end

      it 'should be empty' do
        @e.should be_empty
      end

      it "should match @foo" do
        @e.evaluate([tag('@foo')]).should == true
      end

      it "should match empty tags" do
        @e.evaluate([]).should == true
      end
    end

    context "@foo" do
      before(:each) do
        @e = Gherkin::TagExpression.new(['@foo'])
      end

      it "should match @foo" do
        @e.evaluate([tag('@foo')]).should == true
      end

      it "should not match @bar" do
        @e.evaluate([tag('@bar')]).should == false
      end

      it "should not match no tags" do
        @e.evaluate([]).should == false
      end
    end

    context "!@foo" do
      before(:each) do
        @e = Gherkin::TagExpression.new(['~@foo'])
      end

      it "should match @bar" do
        @e.evaluate([tag('@bar')]).should == true
      end

      it "should not match @foo" do
        @e.evaluate([tag('@foo')]).should == false
      end
    end

    context "@foo || @bar" do
      before(:each) do
        @e = Gherkin::TagExpression.new(['@foo,@bar'])
      end

      it "should match @foo" do
        @e.evaluate([tag('@foo')]).should == true
      end

      it "should match @bar" do
        @e.evaluate([tag('@bar')]).should == true
      end

      it "should not match @zap" do
        @e.evaluate([tag('@zap')]).should == false
      end
    end

    context "(@foo || @bar) && !@zap" do
      before(:each) do
        @e = Gherkin::TagExpression.new(['@foo,@bar', '~@zap'])
      end

      it "should match @foo" do
        @e.evaluate([tag('@foo')]).should == true
      end

      it "should not match @foo @zap" do
        @e.evaluate([tag('@foo'), tag('@zap')]).should == false
      end
    end

    context "(@foo:3 || !@bar:4) && @zap:5" do
      before(:each) do
        @e = Gherkin::TagExpression.new(['@foo:3,~@bar','@zap:5'])
      end

      it "should count tags for positive tags" do
        rubify_hash(@e.limits).should == {'@foo' => 3, '@zap' => 5}
      end

      it "should match @foo @zap" do
        @e.evaluate([tag('@foo'), tag('@zap')]).should == true
      end
    end

    context "Parsing '@foo:3,~@bar', '@zap:5'" do
      before(:each) do
        @e = Gherkin::TagExpression.new([' @foo:3 , ~@bar ', ' @zap:5 '])
      end

      unless defined?(JRUBY_VERSION)
        it "should split and trim (ruby implementation detail)" do
          @e.__send__(:ruby_expression).should == "(!vars['@bar']||vars['@foo'])&&(vars['@zap'])"
        end
      end

      it "should have limits" do
        rubify_hash(@e.limits).should == {"@zap"=>5, "@foo"=>3}
      end
    end

    context "Tag limits" do
      it "should be counted for negative tags" do
        @e = Gherkin::TagExpression.new(['~@todo:3'])
        rubify_hash(@e.limits).should == {"@todo"=>3}
      end

      it "should be counted for positive tags" do
        @e = Gherkin::TagExpression.new(['@todo:3'])
        rubify_hash(@e.limits).should == {"@todo"=>3}
      end

      it "should raise an error for inconsistent limits" do
        lambda do
          @e = Gherkin::TagExpression.new(['@todo:3', '~@todo:4'])
        end.should raise_error(/Inconsistent tag limits for @todo: 3 and 4/)
      end

      it "should allow duplicate consistent limits" do
        @e = Gherkin::TagExpression.new(['@todo:3', '~@todo:3'])
        rubify_hash(@e.limits).should == {"@todo"=>3}
      end
    end
  end
end
