require 'sinatra'
require 'omniauth-fitbit'

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :fitbit, '<consumer_key>', '<consumer_secret>'
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