module Fitbit
  class Api < OmniAuth::Strategies::Fitbit
    
    def api_call consumer_key, consumer_secret, params, auth_token="", auth_secret=""
      request = build_request(consumer_key, consumer_secret, auth_token, auth_secret)
      request_url = build_url(@@api_version, params)
      request_http_method = get_http_method(params['api-method'])
      request.request( request_http_method,  "http://api.fitbit.com#{request_url}" )
    end

    def build_url api_version, params
      api_method = get_api_method(params['api-method'])
      api_format = params['response-format']
      api_query = uri_encode_query(params['query']) if params['query']
      api_query ||= ""
      request_url = "/#{api_version}/#{api_method}.#{api_format}#{api_query}"
    end

    private 

    def get_api_method method
      api_method = @@fitbit_methods["#{method}"]['resources']
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
      'API-Search-Foods' => { 'http_method' => 'get', 'resources' => ['foods', 'search'] }
    }

  end
end
