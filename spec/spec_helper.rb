# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path(__dir__)
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'omniauth-oauth2'
require 'omniauth_fitbit'

RSpec.configure do |config|
  config.include WebMock::API
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy
end
