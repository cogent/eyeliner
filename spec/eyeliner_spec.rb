require 'spec_helper'

describe Eyeliner::Inliner do

  let(:eyeliner) { Eyeliner::Inliner.new }

  def should_not_modify(input)
    eyeliner.inline(input).should == input
  end

  def should_modify(input, options)
    eyeliner.inline(input).should == options[:to]
  end

  context "with no CSS" do

    describe "#inline" do

      context "with empty input" do

        it "returns empty output" do
          should_not_modify("")
        end

      end

      context "with an HTML fragment" do

        it "returns the same output" do
          should_not_modify("<div>abc</div>")
        end

      end

    end

  end

  context "with some explicit CSS" do

    before do
      eyeliner.css << %{
        .box { border: 1px solid green; }
      }
    end

    describe "#inline" do

      it "adds style attributes to matching elements" do
        should_modify(%(<p class="box">xyz</p>), :to => %(<p class="box" style="border: 1px solid green;">xyz</p>))
      end

      it "leaves non-matching elements alone" do
        should_not_modify("<p>xyz</p>")
      end

    end

  end


end
