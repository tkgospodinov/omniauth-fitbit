require 'omniauth'
require 'omniauth/strategies/oauth'

module OmniAuth
  module Strategies
    class Fitbit < OmniAuth::Strategies::OAuth

      option :name, "fitbit"

      option :client_options, {
          :site => 'http://api.fitbit.com',
          :request_token_path => '/oauth/request_token',
          :access_token_path => '/oauth/access_token',
          :authorize_path => '/oauth/authorize'
      }

      uid do
        access_token.params['encoded_user_id']
      end

      info do
        {
            :display_name => raw_info["user"]["fullName"]
        }
      end

      extra do
        { 
            :raw_info => raw_info
        }
      end

      def raw_info
        @raw_info ||= MultiJson.load(access_token.get("http://api.fitbit.com/1/user/-/profile.json").body)
      end
    end
  end
end