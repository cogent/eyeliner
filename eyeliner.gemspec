# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eyeliner/version"

Gem::Specification.new do |s|

  s.name        = "eyeliner"
  s.version     = Eyeliner::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mike Williams", "Rob Mitchell"]
  s.email       = ["mike@cogentconsulting.com.au", "rob@cogentconsulting.com.au"]
  s.homepage    = "http://github.com/cogent/eyeliner"
  s.summary     = %q{Eyeliner puts CSS makeup on your HTML emails.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

end
