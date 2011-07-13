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
        .small { font-size: 8px; }
      }
    end

    describe "#inline" do

      it "leaves non-matching elements alone" do
        should_not_modify("<p>xyz</p>")
      end

      it "adds style attributes to matching elements" do
        should_modify %(<p class="box">xyz</p>),
               :to => %(<p class="box" style="border: 1px solid green;">xyz</p>)
      end

      it "iterates into nested elements" do
        should_modify %(<p><span class="small">xyz</span></p>),
               :to => %(<p><span class="small" style="font-size: 8px;">xyz</span></p>)
      end

      it "combines all matching rules" do
        should_modify %(<p class="small box">xyz</p>),
               :to => %(<p class="small box" style="border: 1px solid green; font-size: 8px;">xyz</p>)
      end

    end

  end

  context "where CSS rules conflict" do

    before do
      eyeliner.css << %{
        p { color: red; }
        p.small { text-decoration: underline; }
        .small { font-size: 8px; }
      }
    end

    describe "#inline" do

      it "applies styles in order of specificity" do
        should_modify %(<p class="small">xyz</p>),
               :to => %(<p class="small" style="color: red; font-size: 8px; text-decoration: underline;">xyz</p>)
      end

    end

  end

end
