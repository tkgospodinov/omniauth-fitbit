# frozen_string_literal: true

require 'sinatra'
require 'omniauth-fitbit'

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :fitbit, '', '', scope: 'profile', redirect_uri: 'http://localhost:4567/auth/fitbit/callback'
end

get '/' do
  <<-HTML
  <a href='/auth/fitbit'>Sign in with Fitbit</a>
  HTML
end

get '/auth/fitbit/callback' do
  # Do whatever you want with the data
  MultiJson.encode(request.env['omniauth.auth'])
end
