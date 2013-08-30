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
      api_url_resources = get_url_resources(params['api-method'])
      api_format = get_response_format(params['response-format'])
      api_required = add_api_ids(api_url_resources, params)
      api_query = uri_encode_query(params['query']) unless params['query'].nil?
      api_query ||= ""
      request_url = "/#{api_version}/#{api_required}.#{api_format}#{api_query}"
    end

    def add_api_ids api_method, params
      ids = ['from-user-id', 'activity-id']
      ids.each { |x| api_method << "/#{params[x]}" if params.has_key? x }
      api_method
    end

    def get_response_format api_format
      !api_format.nil? && api_format.downcase == 'json' ? 'json' : 'xml'
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
      
      if (@@fitbit_methods[api_method].has_key? 'required') && (lowercase.keys & required != required)
        return ["#{api_method} requires #{required}. You're missing #{required - lowercase.keys}."]
      end
      lowercase
    end

    def get_lowercase params
      Hash[params.map { |k,v| [k.downcase, v.downcase] }]
    end

    def get_url_resources method
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
      },
      'api-add-favorite-activity' => {
        'http_method' => 'post',
        'resources'   => ['user', '-', 'activities', 'favorite']
      }
    }

  end

end
