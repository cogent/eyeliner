require 'nokogiri'
require 'css_parser'

class Eyeliner

  def initialize(attributes = {})
    @css = attributes[:css] || ""
    @stylesheet_base = attributes[:stylesheet_base]
  end

  attr_accessor :stylesheet_base

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

  def css
    @css.dup
  end

  def apply_to(input)
    Application.new(self, input).apply
  end

  # encapsulates the application of CSS to some HTML input
  class Application

    def initialize(eyeliner, input)
      @eyeliner = eyeliner
      @input = input
      @css = @eyeliner.css
    end

    def apply
      parse_input
      extract_stylesheets
      parse_css
      map_styles_to_elements
      apply_styles_to_elements
      @doc.to_html
    end

    private

    def parse_input
      @doc = case @input
      when Nokogiri::XML::Node
        @input
      else
        Nokogiri::HTML.parse(@input)
      end
    end

    def extract_stylesheets
      @doc.css("style, link[rel=stylesheet][type='text/css']").each do |element|
        next if has_class("noinline", element)
        case element.name
        when "style"
          @css << element.content
        when "link"
          @css << read_stylesheet(element["href"])
        end
        element.remove unless has_class("retain", element)
      end
    end

    def has_class(class_name, element)
      element["class"] && element["class"].split.member?(class_name)
    end
    
    def read_stylesheet(name)
      name_without_query = name.sub(%r{\?.*}, '')
      full_path = File.join(@eyeliner.stylesheet_base, name_without_query)
      File.read(full_path)
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
        @doc.css(selector, PsuedoClassHandler.new).each do |element|
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

  class PsuedoClassHandler

    %w(visited active hover focus).each do |psuedo_class|
      define_method(psuedo_class) do |node_set|
        []
      end
    end

  end

end
