# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rinda/version"

Gem::Specification.new do |s|
  s.name        = "more_rinda"
  s.version     = MoreRinda::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Masatoshi Seki"]
  s.homepage    = "https://github.com/seki/MoreRinda"
  s.summary     = %q{Various extensions for Rinda::TupleSpace lovers.}
  s.description = ""

  s.rubyforge_project = "drip"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end