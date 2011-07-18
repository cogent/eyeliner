require 'nokogiri'
require 'css_parser'

class Eyeliner

  def initialize
    @css = ""
  end

  StyleRule = Struct.new(:declarations, :specificity) do

    def <=>(other)
      specificity <=> other.specificity
    end

    def to_s
      declarations
    end

  end

  def add_css(css)
    @css << css
  end

  def apply_to(input)
    Application.new(input, @css).apply
  end

  # encapsulates the application of CSS to some HTML input
  class Application

    def initialize(input, css)
      @input = input
      @css = css
    end

    def apply
      parse_input
      parse_css
      map_styles_to_elements
      apply_styles_to_elements
      @doc.to_html
    end

    private

    def parse_input
      @doc = Nokogiri::HTML.fragment(@input)
    end

    def parse_css
      @css_parser = CssParser::Parser.new
      @css_parser.add_block!(@css)
      @styles_by_element = Hash.new do |h,k|
        h[k] = []
      end
    end

    def map_styles_to_elements
      @css_parser.each_selector do |selector, declarations, specificity|
        @doc.css(selector).each do |element|
          @styles_by_element[element] << StyleRule.new(declarations, specificity)
        end
      end
    end

    def apply_styles_to_elements
      @styles_by_element.each do |element, rules|
        parts = rules.sort
        parts.push(element["style"]) if element["style"]
        element["style"] = parts.join(" ")
      end
    end

  end

end
