module Fitbit
  class Api < OmniAuth::Strategies::Fitbit
    
    def api_call consumer_key, consumer_secret, params, auth_token="", auth_secret=""
      api_params = get_lowercase(params)
      api_error = return_any_api_errors(api_params, auth_token, auth_secret)
      raise api_error if api_error
      access_token = build_request(consumer_key, consumer_secret, auth_token, auth_secret)
      send_api_request(api_params, access_token)
    end

    def build_url api_version, params
      api_url_resources = get_url_resources(params)
      api_format = get_response_format(params['response-format'])
      api_query = uri_encode_query(params['query']) 
      request_url = "/#{api_version}/#{api_url_resources}.#{api_format}#{api_query}"
    end

    def get_fitbit_methods
      @@fitbit_methods
    end

    private 

    def return_any_api_errors params, auth_token, auth_secret
      api_error = nil
      api_method = params['api-method']
      fitbit_api_method = @@fitbit_methods[api_method]

      if !fitbit_api_method
        api_error = "#{params['api-method']} is not a valid Fitbit API method." 
      elsif is_missing_required_parameters? fitbit_api_method, params
        api_error = required_parameters_error(api_method, params.keys)
      elsif is_missing_post_parameters? fitbit_api_method, params.keys
        api_error = post_parameters_error(api_method, params.keys)
      elsif is_breaking_exclusive_post_parameter_rule? fitbit_api_method, params.keys
        api_error = exclusive_post_parameters_error(api_method, params.keys)
      elsif fitbit_api_method['auth_required'] && (auth_token == "" || auth_secret == "")
        if fitbit_api_method['auth_required'].is_a? String
          fitbit_auth = fitbit_api_method['auth_required']
          api_error = "#{api_method} requires user auth_token and auth_secret, unless you include [\"#{fitbit_auth}\"]." unless params[fitbit_auth]
        else
          api_error = "#{api_method} requires user auth_token and auth_secret."
        end
      end
    end

    def get_lowercase params
      api_strings = Hash[params.map { |k,v| [k, v.downcase] if k == 'api-method' }]
      api_parameters_and_headers = Hash[params.map { |k,v| [k, v] if k != 'api-method' }]
      api_strings.merge(api_parameters_and_headers)
    end
    
    def is_fitbit_api_method? api_method
      @@fitbit_methods.has_key? api_method
    end

    def is_missing_required_parameters? fitbit_api_method, params
      required = fitbit_api_method['required_parameters'] 
      required_parameters = get_required_parameters(required, params)
      (required) && ((required_parameters.is_a? Hash) || (params.keys & required_parameters != required_parameters))
    end

    def get_required_parameters required_parameters, params
      if required_parameters.is_a? Hash
        required_parameters.keys.each do |x| 
          return required_parameters[x] if params.keys.include? x 
        end
      end
      required_parameters
    end

    def is_missing_post_parameters? fitbit_api_method, supplied_parameters
      if fitbit_api_method['post_parameters'] 
        required_post_parameters = fitbit_api_method['post_parameters'].select { |x| !x.is_a? Array } 
      end
      (required_post_parameters) &&
        (required_post_parameters & supplied_parameters != required_post_parameters)
    end

    def is_breaking_exclusive_post_parameter_rule? api_method, params
      exclusive_post_parameters = get_exclusive_post_parameters api_method
      supplied_post_parameters = params
      count = 0
      if exclusive_post_parameters && supplied_post_parameters
        supplied_post_parameters.each do |parameter|
          count +=1 if exclusive_post_parameters.include? parameter
        end
      end

      count > 1
    end

    def get_exclusive_post_parameters fitbit_api_method
      post_parameters = fitbit_api_method['post_parameters']
      exclusive_post_parameters = post_parameters.select { |x| x.is_a? Array } if post_parameters 
      exclusive_post_parameters.flatten if exclusive_post_parameters
    end

    def required_parameters_error api_method, supplied
      required = @@fitbit_methods[api_method]['required_parameters'] 
      if required.is_a? Hash
        count = 1
        error = "#{api_method} requires 1 of #{required.length} options: "
        required.keys.each do |x|
          error << "(#{count}) #{required[x]} "
          count += 1
        end
      else
        error = "#{api_method} requires #{required}. You're missing #{required-supplied}."
      end
      error
    end

    def post_parameters_error api_method, supplied
      required = @@fitbit_methods[api_method]['post_parameters']
      "#{api_method} requires POST Parameters #{required}. You're missing #{required-supplied}."
    end

    def exclusive_post_parameters_error api_method, supplied
      exclusive_post_parameters = get_exclusive_post_parameters @@fitbit_methods[api_method]
      all_supplied = exclusive_post_parameters & supplied
      all_supplied_string = all_supplied.map { |data| "'#{data}'" }.join(' AND ')
      "#{api_method} allows only one of these POST Parameters #{exclusive_post_parameters}. You used #{all_supplied_string}."
    end

    def build_request consumer_key, consumer_secret, auth_token, auth_secret
      fitbit = Fitbit::Api.new :fitbit, consumer_key, consumer_secret
      access_token = OAuth::AccessToken.new fitbit.consumer, auth_token, auth_secret
    end

    def send_api_request params, access_token
      request_url = build_url(@@api_version, params)
      request_http_method = get_http_method(params['api-method'])
      request_headers = get_request_headers(params) 
      access_token.request( request_http_method, "http://api.fitbit.com#{request_url}", "",  request_headers )
    end
    
    def get_http_method method
      api_http_method = @@fitbit_methods["#{method}"]['http_method']
    end
    
    def get_request_headers params
      api_method = params['api-method']
      available_headers = @@fitbit_methods[api_method]['request_headers'] & params.keys
      Hash[params.each { |k,v| [k,v] if available_headers.include? k }] if available_headers
    end

    def get_url_resources params
      api_method = params['api-method'].downcase
      fitbit_api_method = @@fitbit_methods[api_method]
      dynamic_resources = fitbit_api_method['required_parameters']
      api_ids = get_required_parameters(dynamic_resources, params) 
      resources = fitbit_api_method['resources']
      api_resources = get_required_parameters(resources, params)

      api_resources.each do |x|
        i = api_resources.index(x)
        id = x.delete "<>"
        if api_ids && (api_ids.include? id) && (!api_ids.include? x)
          api_resources[i] = params[id]
          api_ids.delete(x)
        end
        if x == '-' && fitbit_api_method['auth_required'] == 'user-id'
          api_resources[i] = params['user-id'] if params['user-id']
        end
      end
      api_method_url = api_resources.join("/")
    end

    def get_response_format api_format
      !api_format.nil? && api_format.downcase == 'json' ? 'json' : 'xml'
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
        'auth_required'       => false,
        'http_method'         => 'get',
        'required_parameters' => ['query'],
        'resources'           => ['foods', 'search'],
      },
      'api-accept-invite' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['accept'],
        'required_parameters' => ['from-user-id'],
        'resources'           => ['user', '-', 'friends', 'invitations', '<from-user-id>'],
      },
      'api-add-favorite-activity' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'required_parameters' => ['activity-id'],
        'resources'           => ['user', '-', 'activities', 'favorite', '<activity-id>'],
      },
      'api-add-favorite-food' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'required_parameters' => ['food-id'],
        'resources'           => ['user', '-', 'foods', 'log', 'favorite', '<food-id>'],
      },
      'api-browse-activites' => {
        'auth_required'       => false,
        'http_method'         => 'get',
        'request_headers'     => ['accept-locale'],
        'resources'           => ['activities'],
      },
      'api-config-friends-leaderboard' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['hideMeFromLeaderboard'],
        'request_headers'     => ['accept-language'],
        'resources'           => ['user', '-', 'friends', 'leaderboard'],
      },
      'api-create-food' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['name', 'defaultFoodMeasurementUnitId', 'defaultServingSize', 'calories'],
        'request_headers'     => ['accept-locale'],
        'resources'           => ['foods'],
      },
      'api-create-invite' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     =>  [['invitedUserEmail', 'invitedUserId']],
        'resources'           => ['user', '-', 'friends', 'invitations'],
      },
      'api-delete-activity-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['activity-log-id'],
        'resources'           => ['user', '-', 'activities', '<activity-log-id>'],
      },
      'api-delete-blood-pressure-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['bp-log-id'],
        'resources'           => ['user', '-', 'bp', '<bp-log-id>'],
      },
      'api-delete-body-fat-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['body-fat-log-id'],
        'resources'           => ['user', '-', 'body', 'log', 'fat', '<body-fat-log-id>'],
      },
      'api-delete-body-weight-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['body-weight-log-id'],
        'resources'           => ['user', '-', 'body', 'log', 'weight', '<body-weight-log-id>'],
      },
      'api-delete-favorite-activity' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['activity-id'],
        'resources'           => ['user', '-', 'activities', 'favorite', '<activity-id>'],
      },
      'api-delete-favorite-food' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['food-id'],
        'resources'           => ['user', '-', 'foods', 'log', 'favorite', '<food-id>'],
      },
      'api-delete-food-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['food-log-id'],
        'resources'           => ['user', '-', 'foods', 'log', '<food-log-id>'],
      },
      'api-delete-heart-rate-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['heart-log-id'],
        'resources'           => ['user', '-', 'heart', '<heart-log-id>'],
      },
      'api-delete-sleep-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['sleep-log-id'],
        'resources'           => ['user', '-', 'sleep', '<sleep-log-id>'],
      },
      'api-delete-water-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['water-log-id'],
        'resources'           => ['user', '-', 'foods', 'log', 'water', '<water-log-id>'],
      },
      'api-devices-add-alarm' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['time', 'enabled', 'recurring', 'weekDays'],
        'request_headers'     => ['accept-language'],
        'required_parameters' => ['device-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms'],
      },
      'api-devices-delete-alarm' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'required_parameters' => ['device-id', 'alarm-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms', '<alarm-id>'],
      },
      'api-devices-get-alarms' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'required_parameters' => ['device-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms'],
      },
      'api-devices-update-alarm' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['time', 'enabled', 'recurring', 'weekDays', 'snoozeLength', 'snoozeCount'],
        'request_headers'     => ['accept-language'],
        'required_parameters' => ['device-id', 'alarm-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms', '<alarm-id>'],
      },
      'api-get-activities' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['accept-locale', 'accept-language'],
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'activities', 'date', '<date>'],
      },
      'api-get-activity' => {
        'auth_required'       => false,
        'http_method'         => 'get',
        'request_headers'     => ['accept-locale'],
        'required_parameters' => ['activity-id'],
        'resources'           => ['activities', '<activity-id>'],
      },
      'api-get-activity-daily-goals' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['accept-language'],
        'resources'           => ['user', '-', 'activities', 'goals', 'daily'],
      },
      'api-get-activity-stats' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['accept-language'],
        'resources'           => ['user', '-', 'activities'],
      },
      'api-get-activity-weekly-goals' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['accept-language'],
        'resources'           => ['user', '-', 'activities', 'goals', 'weekly'],
      },
      'api-get-badges' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['accept-locale'],
        'resources'           => ['user', '-', 'badges'],
      },
      'api-get-blood-pressure' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'bp', 'date', '<date>'],
      },
      'api-get-body-fat' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'required_parameters' => {
          'date'      => ['date'],
          'end-date'  => ['base-date', 'end-date'],
          'period'    => ['base-date', 'period'],
        },
        'resources'           => {
          'date'      => ['user', '-', 'body', 'log', 'fat', 'date', '<date>'],
          'end-date'  => ['user', '-', 'body', 'log', 'fat', 'date', '<base-date>', '<end-date>'],
          'period'    => ['user', '-', 'body', 'log', 'fat', 'date', '<base-date>', '<period>'],
        }
      },
    }

  end

end
