module Fitbit
  class Api < OmniAuth::Strategies::Fitbit
    
    def api_call consumer_key, consumer_secret, params, auth_token="", auth_secret=""
      api_params = valid_params(params, auth_token, auth_secret)
      return api_params[0] if api_params.is_a? Array
      access_token = build_request(consumer_key, consumer_secret, auth_token, auth_secret)
      send_api_request(api_params, access_token)
    end

    def build_url api_version, params
      api_url_resources = get_url_resources(params['api-method'])
      api_format = get_response_format(params['response-format'])
      api_ids = add_api_ids(api_url_resources, params)
      api_query = uri_encode_query(params['query']) 
      request_url = "/#{api_version}/#{api_ids}.#{api_format}#{api_query}"
    end

    private 

    def valid_params params, auth_token, auth_secret
      lowercase = get_lowercase(params)
      api_method = lowercase['api-method']

      if @@fitbit_methods.has_key? api_method
        required = @@fitbit_methods[api_method]['required'] 
        post_parameters = @@fitbit_methods[api_method]['post_parameters']
      else
        return ["#{params['api-method']} is not a valid Fitbit API method."] 
      end
      
      if (@@fitbit_methods[api_method].has_key? 'required') && (lowercase.keys & required != required)
        return [build_error_message(api_method, required, required - lowercase.keys)]
      end
      
      if @@fitbit_methods[api_method].has_key? 'post_parameters'
        lowercase_parameters = lowercase['post_parameters']
        if lowercase_parameters.nil? || !lowercase_parameters.is_a?(Hash)
          return [post_parameters_error(api_method, post_parameters, post_parameters)]
        elsif ((post_parameters & lowercase_parameters.keys) != post_parameters)
          return [post_parameters_error(api_method, post_parameters, post_parameters - lowercase['post_parameters'].keys)]
        end
      end

      if @@fitbit_methods[api_method]['auth_required'] && (auth_token == "" || auth_secret == "")
        return ["#{api_method} requires user auth_token and auth_secret."]
      end
      
      lowercase
    end

    def build_error_message api_method, required, missing
      "#{api_method} requires #{required}. You're missing #{missing}."
    end

    def post_parameters_error api_method, required, missing
      "#{api_method} requires POST Parameters #{required}. You're missing #{missing}."
    end

    def build_request consumer_key, consumer_secret, auth_token, auth_secret
      fitbit = Fitbit::Api.new :fitbit, consumer_key, consumer_secret
      access_token = OAuth::AccessToken.new fitbit.consumer, auth_token, auth_secret
    end

    def send_api_request api_params, access_token
      request_url = build_url(@@api_version, api_params)
      request_http_method = get_http_method(api_params['api-method'])
      request_headers = api_params['request_headers']
      access_token.request( request_http_method, "http://api.fitbit.com#{request_url}", "",  request_headers )
    end
    
    def get_http_method method
      api_http_method = @@fitbit_methods["#{method}"]['http_method']
    end

    def get_url_resources method
      api_method = @@fitbit_methods["#{method.downcase}"]['resources']
      api_method_url = api_method.join("/")
    end

    def get_response_format api_format
      !api_format.nil? && api_format.downcase == 'json' ? 'json' : 'xml'
    end

    def add_api_ids api_method, params
      ids = ['from-user-id', 'activity-id', 'food-id']
      ids.each { |x| api_method << "/#{params[x]}" if params.has_key? x }
      api_method
    end

    def get_lowercase params
      api_strings = Hash[params.map { |k,v| [k.downcase, v.downcase] if v.is_a? String }]
      api_parameters_and_headers = Hash[params.map { |k,v| [k.downcase, v] if !v.is_a? String }]
      api_strings.merge(api_parameters_and_headers)
    end

    def uri_encode_query query
      if query.nil?
        ""
      else
        api_query = OAuth::Helper.normalize({ 'query' => query }) 
        "?#{api_query}"
      end
    end

    @@api_version = 1

    @@fitbit_methods = {
      'api-search-foods' => {
        'http_method'     => 'get',
        'resources'       => ['foods', 'search'],
        'required'        => ['query'],
        'auth_required'   => false
      },
      'api-accept-invite' => {
        'http_method'     => 'post',
        'resources'       => ['user', '-', 'friends', 'invitations'],
        'post_parameters' => ['accept'],
        'auth_required'   => true
      },
      'api-add-favorite-activity' => {
        'http_method'     => 'post',
        'resources'       => ['user', '-', 'activities', 'favorite'],
        'auth_required'   => true
      },
      'api-add-favorite-food' => {
        'http_method'     => 'post',
        'resources'       => ['user', '-', 'foods', 'log', 'favorite'],
        'auth_required'   => true
      },
      'api-browse-activites' => {
        'http_method'     => 'get',
        'resources'       => ['activities'],
        'auth_required'   => false,
        'request_headers' => ['accept-locale']
      },
      'api-config-friends-leaderboard' => {
        'http_method'     => 'post',
        'resources'       => ['user', '-', 'friends', 'leaderboard'],
        'auth_required'   => true,
        'post_parameters' => ['hideMeFromLeaderboard'],
        'request_headers' => ['accept-language']
      },
      'api-create-food' => {
        'http_method'     => 'post',
        'resources'       => ['foods'],
        'auth_required'   => true,
        'post_parameters' => ['defaultFoodMeasurementUnitId', 'defaultServingSize', 'calories'],
        'request_headers' => ['accept-locale']
      }
    }

  end

end
