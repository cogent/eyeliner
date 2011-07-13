require 'nokogiri'
require 'css_parser'

module Eyeliner

  class Inliner

    attr_accessor :css

    def initialize
      @css = ""
    end

    def inline(input)
      fragment = Nokogiri::HTML.fragment(input)
      css_parser = CssParser::Parser.new
      css_parser.add_block!(css)
      css_parser.each_selector do |selector, declarations, specificity|
        fragment.css(selector).each do |element|
          if element['style']
            element['style'] = element['style'] + " " + declarations
          else
            element['style'] = declarations
          end
        end
      end
      fragment.to_html
    end

  end

end
