require 'sinatra'
require 'omniauth-fitbit'

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :fitbit, 'e2c9d799ffb94b80bce191192fb4500c', '2b38edfa10d446afad5c513e2bc7cff8'
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