require 'spec_helper'

describe Eyeliner do

  let(:eyeliner) { Eyeliner.new }

  def parse_fragment(html)
    Nokogiri::HTML.fragment(html)
  end

  def should_not_modify(input)
    eyeliner.apply_to(parse_fragment(input)).should == input
  end

  def should_modify(input, options)
    eyeliner.apply_to(parse_fragment(input)).should == options[:to]
  end

  it "can be initialized with attributes" do
    eyeliner = Eyeliner.new(:stylesheet_base => "STYLESHEETS", :css => "SOME CSS")
    eyeliner.stylesheet_base.should == "STYLESHEETS"
    eyeliner.css.should == "SOME CSS"
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
      eyeliner.add_css %{
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

  context "where multiple CSS rules apply" do

    before do
      eyeliner.add_css %{
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

      it "retains contents of existing style attribute" do
        should_modify %(<p style="border: 1px solid blue;">xyz</p>),
               :to => %(<p style="color: red; border: 1px solid blue;">xyz</p>)
      end

    end

  end

  %w(visited active hover focus).each do |pseudo_class|
    context "when CSS rule contains pseudo-class :#{pseudo_class}" do

      before do
        eyeliner.add_css %{
          a:#{pseudo_class} { color: red; }
        }
      end

      it "is ignored" do
        should_not_modify("<a>xyz</a>")
      end

    end
  end

  context "when CSS rule contains pseudo-class :link" do

    before do
      eyeliner.add_css %{
        a:link { color: red; }
      }
    end

    it "is not ignored" do
      should_modify %(<a href="foo">xyz</a>),
             :to => %(<a href="foo" style="color: red;">xyz</a>)
    end

  end

  context "when the document contains a <style> block" do

    before do
      @input = <<-HTML
      <html>
      <head>
        <style>
          strong { text-decoration: underline; }
        </style>
      </head>
      <body>
        <p>
          Feeling <strong>STRONG</strong>.
        </p>
      </body>
      </html>
      HTML
    end

    describe "#apply_to" do

      before do
        @output = eyeliner.apply_to(@input)
        @output_doc = Nokogiri::HTML.fragment(@output)
      end

      it "inlines the styles" do
        strong_element = @output_doc.css("strong").first
        strong_element["style"].should == "text-decoration: underline;"
      end

      it "removes the <style> element" do
        @output_doc.css("style").should be_empty
      end

    end

  end

  context "when the document contains a <style> block, classed 'noinline'" do

    before do
      @input = <<-HTML
      <html>
      <head>
        <style class="noinline">
          strong { text-decoration: underline; }
        </style>
      </head>
      <body>
        <p>
          Feeling <strong>STRONG</strong>.
        </p>
      </body>
      </html>
      HTML
    end

    describe "#apply_to" do

      before do
        @output = eyeliner.apply_to(@input)
        @output_doc = Nokogiri::HTML.fragment(@output)
      end

      it "does not inline the styles" do
        strong_element = @output_doc.css("strong").first
        strong_element["style"].should_not == "text-decoration: underline;"
      end

      it "does not remove the <style> element" do
        @output_doc.css("style").should_not be_empty
      end

    end

  end

  context "when the document contains a <style> block, classed 'retain'" do

    before do
      @input = <<-HTML
      <html>
      <head>
        <style class="retain">
          strong { text-decoration: underline; }
        </style>
      </head>
      <body>
        <p>
          Feeling <strong>STRONG</strong>.
        </p>
      </body>
      </html>
      HTML
    end

    describe "#apply_to" do

      before do
        @output = eyeliner.apply_to(@input)
        @output_doc = Nokogiri::HTML.fragment(@output)
      end

      it "inlines the styles" do
        strong_element = @output_doc.css("strong").first
        strong_element["style"].should == "text-decoration: underline;"
      end

      it "does not remove the <style> element" do
        @output_doc.css("style").should_not be_empty
      end

    end

  end

  context "when the document contains a linked stylesheet" do

    before do

      $tmp_dir.mkdir
      ($tmp_dir + "styles.css").open("w") do |css_io|
        css_io.puts <<-CSS
        .email h1 { text-decoration: underline; }
        CSS
      end

      @input = <<-HTML
      <html>
      <head>
        <link rel="stylesheet" href="styles.css?version=123" type="text/css" />
      </head>
      <body class="email">
        <h1>Hello</h1>
      </body>
      </html>
      HTML

    end

    describe "#apply_to" do

      before do
        eyeliner.stylesheet_base = $tmp_dir.to_s
        @output = eyeliner.apply_to(@input)
        @output_doc = Nokogiri::HTML.fragment(@output)
      end

      it "inlines the styles" do
        h1_element = @output_doc.css("h1").first
        h1_element["style"].should == "text-decoration: underline;"
      end

      it "removes the <link> element" do
        @output_doc.css("link").should be_empty
      end

    end

  end

end
