# -*- encoding: utf-8 -*-
# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'omniauth-fitbit/version'

Gem::Specification.new do |s|
  s.name        = 'omniauth-fitbit'
  s.version     = OmniAuth::Fitbit::VERSION
  s.authors     = ['TK Gospodinov']
  s.email       = ['tk@gospodinov.net']
  s.homepage    = 'http://github.com/tkgospodinov/omniauth-fitbit'
  s.summary     = 'OmniAuth OAuth2 strategy for Fitbit'
  s.description = 'OmniAuth OAuth2 strategy for Fitbit'

  s.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  s.executables   = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_runtime_dependency 'omniauth-oauth2', '~> 1.4'
  s.add_runtime_dependency 'multi_xml'

  s.add_development_dependency 'rake'
end
