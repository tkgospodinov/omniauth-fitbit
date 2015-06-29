# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-fitbit/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-fitbit"
  s.version     = OmniAuth::Fitbit::VERSION
  s.authors     = ["TK Gospodinov"]
  s.email       = ["tk@gospodinov.net"]
  s.homepage    = "http://github.com/tkgospodinov/omniauth-fitbit"
  s.summary     = %q{OmniAuth strategy for Fitbit}
  s.description = %q{OmniAuth strategy for Fitbit}

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'omniauth-oauth', '~> 1.0'
  s.add_runtime_dependency 'multi_xml'
  s.add_development_dependency 'rake'
end
