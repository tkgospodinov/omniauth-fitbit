module Fitbit
  class Api < OmniAuth::Strategies::Fitbit
    
    def api_call consumer_key, consumer_secret, params, auth_token="", auth_secret=""
      api_params = valid_params(params)
      return api_params[0] if api_params.is_a? Array
      access_token = build_request(consumer_key, consumer_secret, auth_token, auth_secret)
      request_url = build_url(@@api_version, api_params)
      request_http_method = get_http_method(api_params['api-method'])
      access_token.request( request_http_method,  "http://api.fitbit.com#{request_url}" )
    end

    def build_url api_version, params
      api_method = get_api_method(params['api-method'])
      api_format = params['response-format']
      api_from_user_id = "/#{params['from-user-id']}" if params['from-user-id']
      api_from_user_id ||= ""
      api_query = uri_encode_query(params['query']) if params['query']
      api_query ||= ""
      request_url = "/#{api_version}/#{api_method}#{api_from_user_id}.#{api_format}#{api_query}"
    end

    private 

    def valid_params params
      lowercase = get_lowercase(params)
      api_method = lowercase['api-method']

      if @@fitbit_methods.has_key? api_method
        required = @@fitbit_methods[api_method]['required']
      else
        return ["#{params['api-method']} is not a valid Fitbit API method."] 
      end
      
      if lowercase.keys & required != required
        return ["#{api_method} requires #{required}. You're missing #{required - lowercase.keys}."]
      end
      lowercase
    end

    def get_lowercase params
      Hash[params.map { |k,v| [k.downcase, v.downcase] }]
    end

    def get_api_method method
      api_method = @@fitbit_methods["#{method.downcase}"]['resources']
      api_method_url = api_method.join("/")
    end

    def uri_encode_query query
      api_query = OAuth::Helper.normalize({ 'query' => query })
      "?#{api_query}"
    end

    def build_request consumer_key, consumer_secret, auth_token, auth_secret
      fitbit = Fitbit::Api.new :fitbit, consumer_key, consumer_secret
      access_token = OAuth::AccessToken.new fitbit.consumer, auth_token, auth_secret
    end
    
    def get_http_method method
      api_http_method = @@fitbit_methods["#{method}"]['http_method']
    end

    @@api_version = 1

    @@fitbit_methods = {
      'api-search-foods' => { 
        'http_method' => 'get', 
        'resources'   => ['foods', 'search'],
        'required'    => ['query']
      },
      'api-accept-invite' => {
        'http_method' => 'post',
        'resources'   => ['user', '-', 'friends', 'invitations'],
        'required'    => ['accept']
      }
    }

  end

end
