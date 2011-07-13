require 'nokogiri'
require 'css_parser'

module Eyeliner

  class Inliner

    attr_accessor :css

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

    def inline(input)
      fragment = Nokogiri::HTML.fragment(input)
      css_parser = CssParser::Parser.new
      css_parser.add_block!(css)
      styles_by_element = Hash.new do |h,k|
        h[k] = []
      end
      css_parser.each_selector do |selector, declarations, specificity|
        fragment.css(selector).each do |element|
          styles_by_element[element] << StyleRule.new(declarations, specificity)
        end
      end
      styles_by_element.each do |element, rules|
        element["style"] = rules.sort.join(" ")
      end
      fragment.to_html
    end

  end

end
