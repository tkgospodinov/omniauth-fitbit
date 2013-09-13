module Fitbit
  class Api < OmniAuth::Strategies::Fitbit
    
    def api_call consumer_key, consumer_secret, params, auth_token="", auth_secret=""
      api_params = get_lowercase_api_method(params)
      api_method = api_params['api-method']
      api_error = get_api_errors(api_params, api_method, auth_token, auth_secret)
      raise api_error if api_error
      access_token = build_request(consumer_key, consumer_secret, auth_token, auth_secret)
      send_api_request(api_params, api_method, access_token)
    end

    def get_fitbit_methods
      @@fitbit_methods
    end

    def get_resource_paths
      @@resource_paths
    end

    private 

    def get_api_errors params, api_method, auth_token, auth_secret
      api_error = nil
      fitbit_api_method = @@fitbit_methods[api_method]
      required_parameters = fitbit_api_method['required_parameters'] if fitbit_api_method
      post_parameters = fitbit_api_method['post_parameters'] if fitbit_api_method
      optional_required_parameters = fitbit_api_method['required_if'] if fitbit_api_method
      params_keys = params.keys

      if !fitbit_api_method
        api_error = "#{params['api-method']} is not a valid Fitbit API method." 
      elsif missing_required_parameters? required_parameters, params_keys
        api_error = required_parameters_error(required_parameters, api_method, params_keys)
      elsif missing_post_parameters? post_parameters, params_keys
        api_error = post_parameters_error(post_parameters, api_method, params_keys)
      elsif missing_exclusive_post_parameters? post_parameters, params_keys
        api_error = required_exclusive_post_parameters_error(post_parameters, api_method)
      elsif breaking_exclusive_post_parameter_rule? post_parameters, params_keys
        api_error = exclusive_post_parameters_error(post_parameters, api_method, params_keys)
      elsif missing_optional_required_parameters? optional_required_parameters, params_keys
        api_error = optional_required_parameters_error(optional_required_parameters, api_method, params_keys)
      elsif fitbit_api_method['auth_required'] && (auth_token == "" || auth_secret == "")
        api_error = auth_error(params, api_method, fitbit_api_method['auth_required'])
      end
    end

    def get_lowercase_api_method params
      api_strings = Hash[params.map { |k,v| [k, v.downcase] if k == 'api-method' }]
      api_parameters_and_headers = Hash[params.map { |k,v| [k, v] if k != 'api-method' }]
      api_strings.merge(api_parameters_and_headers)
    end

    def missing_required_parameters? required, params_keys
      required_parameters = get_required_parameters(required, params_keys)
      (required) && ((required_parameters.is_a? Hash) || 
                      (params_keys & required_parameters != required_parameters))
    end

    def get_required_parameters required_parameters, params_keys
      if required_parameters.is_a? Hash
        required_parameters.keys.each do |x| 
          return required_parameters[x] if params_keys.include? x 
        end
      end
      required_parameters
    end

    def missing_post_parameters? post_parameters, supplied_parameters
      if post_parameters
        required_post_parameters = post_parameters.select { |x| x.is_a? String } 
      end
      (required_post_parameters) &&
        (required_post_parameters & supplied_parameters != required_post_parameters)
    end

    def missing_exclusive_post_parameters? post_parameters, supplied_parameters
      if post_parameters
        required_exclusive_post_parameters = post_parameters.select { |x| x.is_a? Array } 
        required_exclusive_post_parameters.flatten!
      end
      supplied_exclusive_post_parameters = required_exclusive_post_parameters & supplied_parameters
      (required_exclusive_post_parameters) && (required_exclusive_post_parameters.length != 0) &&
        (supplied_exclusive_post_parameters.length == 0)
    end

    def breaking_exclusive_post_parameter_rule? post_parameters, params_keys
      exclusive_post_parameters = get_exclusive_post_parameters post_parameters
      supplied_post_parameters = params_keys
      count = 0
      if exclusive_post_parameters && supplied_post_parameters
        supplied_post_parameters.each do |parameter|
          count += 1 if exclusive_post_parameters.include? parameter
        end
      end

      count > 1
    end

    def missing_optional_required_parameters? optional_required_parameters, params_keys
      if optional_required_parameters
        optional_required_parameters.each do |k,v|
          if (params_keys.include? k) && (params_keys & v != v)
            return true
          end
        end
      end
      false
    end

    def get_exclusive_post_parameters post_parameters
      exclusive_post_parameters = post_parameters.select { |x| x.is_a? Array } if post_parameters 
      exclusive_post_parameters.flatten if exclusive_post_parameters
    end

    def invalid_resource_path? api_method, resource_path
      error = false
      if resource_path && api_method == 'api-get-time-series'
        error = true if !@@resource_paths.include? resource_path
      end
      error
    end
    

    def required_parameters_error required, api_method, supplied
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

    def post_parameters_error required, api_method, supplied
      "#{api_method} requires POST Parameters #{required}. You're missing #{required-supplied}."
    end

    def required_exclusive_post_parameters_error required, api_method
      required_exclusive = required.select{ |x| x.is_a? Array }
      required_exclusive.flatten!
      "#{api_method} requires one of these POST parameters: #{required_exclusive}."
    end

    def exclusive_post_parameters_error post_parameters, api_method, supplied
      exclusive = get_exclusive_post_parameters(post_parameters)
      all_supplied = exclusive & supplied
      all_supplied_string = all_supplied.map { |data| "'#{data}'" }.join(' AND ')
      "#{api_method} allows only one of these POST Parameters #{exclusive}. You used #{all_supplied_string}."
    end

    def optional_required_parameters_error optional_required_parameters, api_method, supplied
      required_if = optional_required_parameters.values.flatten
      "#{api_method} requires #{required_if} when you use #{optional_required_parameters.keys}."
    end

    def auth_error params, api_method, auth_required
      if auth_required.is_a? String
        fitbit_auth = auth_required
        "#{api_method} requires user auth_token and auth_secret, unless you include [\"#{fitbit_auth}\"]." unless params[fitbit_auth]
      else
        "#{api_method} requires user auth_token and auth_secret."
      end
    end

    def build_request consumer_key, consumer_secret, auth_token, auth_secret
      fitbit = Fitbit::Api.new :fitbit, consumer_key, consumer_secret
      access_token = OAuth::AccessToken.new fitbit.consumer, auth_token, auth_secret
    end

    def send_api_request params, api_method, access_token
      request_url = build_url(params, api_method)
      request_http_method = @@fitbit_methods[api_method]['http_method']
      request_headers = get_request_headers(params, api_method)
      access_token.request( request_http_method, "http://api.fitbit.com#{request_url}", "",  request_headers )
    end

    def build_url params, api_method
      api_version = @@api_version
      api_url_resources = get_url_resources(params, api_method)
      api_format = get_response_format(params['response-format'])
      api_query = uri_encode_query(params['query']) 
      request_url = "/#{api_version}/#{api_url_resources}.#{api_format}#{api_query}"
    end
    
    def get_request_headers params, api_method
      available_headers = @@fitbit_methods[api_method]['request_headers'] & params.keys
      Hash[params.each { |k,v| [k,v] if available_headers.include? k }] if available_headers
    end

    def get_url_resources params, api_method
      fitbit_api_method = @@fitbit_methods[api_method]
      required_parameters = fitbit_api_method['required_parameters']
      api_ids = get_required_parameters(required_parameters, params.keys) 
      resources = fitbit_api_method['resources']
      api_resources = get_required_parameters(resources, params.keys)

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

    @@resource_paths = [
      'activities/calories',
      'activities/caloriesBMR',
      'activities/steps',
      'activities/distance',
      'activities/floors',
      'activities/elevation',
      'activities/minutesSedentary',
      'activities/minutesLightlyActive',
      'activities/minutesFairlyActive',
      'activities/minutesVeryActive',
      'activities/activityCalories',
      'activities/tracker/calories',
      'activities/tracker/steps',
      'activities/tracker/distance',
      'activities/tracker/floors',
      'activities/tracker/minutesSedentary',
      'activities/tracker/minutesLightlyActive',
      'activities/tracker/minutesFairlyActive',
      'activities/tracker/minutesVeryActive',
      'activities/tracker/activityCalories',
      'body/weight',
      'body/bmi',
      'body/fat',
      'foods/log/caloriesIn',
      'foods/log/water',
      'sleep/startTime',
      'sleep/timeInBed',
      'sleep/minutesAsleep',
      'sleep/awakeningsCount',
      'sleep/minutesAwake',
      'sleep/minutesToFallAsleep',
      'sleep/minutesAfterWakeup',
      'sleep/efficiency'
    ]

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
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['activities'],
      },
      'api-config-friends-leaderboard' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['hideMeFromLeaderboard'],
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'friends', 'leaderboard'],
      },
      'api-create-food' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['name', 'defaultFoodMeasurementUnitId', 'defaultServingSize', 'calories'],
        'request_headers'     => ['Accept-Locale'],
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
        'request_headers'     => ['Accept-Language'],
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
        'request_headers'     => ['Accept-Language'],
        'required_parameters' => ['device-id', 'alarm-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms', '<alarm-id>'],
      },
      'api-get-activities' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale', 'Accept-Language'],
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'activities', 'date', '<date>'],
      },
      'api-get-activity' => {
        'auth_required'       => false,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'required_parameters' => ['activity-id'],
        'resources'           => ['activities', '<activity-id>'],
      },
      'api-get-activity-daily-goals' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'activities', 'goals', 'daily'],
      },
      'api-get-activity-stats' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'activities'],
      },
      'api-get-activity-weekly-goals' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'activities', 'goals', 'weekly'],
      },
      'api-get-badges' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
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
        'request_headers'     => ['Accept-Language'],
        'resources'           => {
          'date'      => ['user', '-', 'body', 'log', 'fat', 'date', '<date>'],
          'end-date'  => ['user', '-', 'body', 'log', 'fat', 'date', '<base-date>', '<end-date>'],
          'period'    => ['user', '-', 'body', 'log', 'fat', 'date', '<base-date>', '<period>'],
        }
      },
      'api-get-body-fat-goal' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'resources'           => ['user', '-', 'body', 'log', 'fat', 'goal'],
      },
      'api-get-body-measurements' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'body', 'date', '<date>'],
      },
      'api-get-body-weight' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'required_parameters' => {
          'date'      => ['date'],
          'end-date'  => ['base-date', 'end-date'],
          'period'    => ['base-date', 'period'],
        },
        'resources'           => {
          'date'      => ['user', '-', 'body', 'log', 'weight', 'date', '<date>'],
          'end-date'  => ['user', '-', 'body', 'log', 'weight', 'date', '<base-date>', '<end-date>'],
          'period'    => ['user', '-', 'body', 'log', 'weight', 'date', '<base-date>', '<period>'],
        }
      },
      'api-get-body-weight-goal' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'body', 'log', 'weight', 'goal'],
      },
      'api-get-device' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'required_parameters' => ['device-id'],
        'resources'           => ['user', '-', 'devices', '<device-id>'],
      },
      'api-get-devices' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'resources'           => ['user', '-', 'devices'],
      },
      'api-get-favorite-activities' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['user', '-', 'activities', 'favorite'],
      },
      'api-get-favorite-foods' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'resources'           => ['user', '-', 'foods', 'log', 'favorite'],
      },
      'api-get-food' => {
        'auth_required'       => false,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'required_parameters' => ['food-id'],
        'resources'           => ['foods', '<food-id>'],
      },
      'api-get-food-goals' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'resources'           => ['user', '-', 'foods', 'log', 'goal'],
      },
      'api-get-foods' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'foods', 'log', 'date', '<date>'],
      },
      'api-get-food-units' => {
        'auth_required'       => false,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['foods', 'units'],
      },
      'api-get-frequent-activities' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale', 'Accept-Language'],
        'resources'           => ['user', '-', 'activities', 'frequent'],
      },
      'api-get-frequent-foods' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['user', '-', 'foods', 'log', 'frequent'],
      },
      'api-get-friends' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'friends'],
      },
      'api-get-friends-leaderboard' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'friends', 'leaderboard'],
      },
      'api-get-glucose' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'glucose', 'date', '<date>'],
      },
      'api-get-heart-rate' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'heart', 'date', '<date>'],
      },
      'api-get-invites' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'resources'           => ['user', '-', 'friends', 'invitations'],
      },
      'api-get-meals' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['user', '-', 'meals'],
      },
      'api-get-recent-activities' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale', 'Accept-Language'],
        'resources'           => ['user', '-', 'activities', 'recent'],
      },
      'api-get-sleep' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'sleep', 'date', '<date>'],
      },
      'api-get-time-series' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'required_parameters' => {
          'end-date'  => ['base-date', 'end-date', 'resource-path'],
          'period'    => ['base-date', 'period', 'resource-path'],
        },
        'resources'           => {
          'end-date'  => ['user', '-', '<resource-path>', 'date', '<base-date>', '<end-date>'],
          'period'    => ['user', '-', '<resource-path>', 'date', '<base-date>', '<period>'],
        },
      },
      'api-get-user-info' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'profile'],
      },
      'api-get-water' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'required_parameters' => ['date'],
        'resources'           => ['user', '-', 'foods', 'log', 'water', 'date', '<date>'],
      },
      'api-log-activity' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => [['activityId', 'activityName'], 'startTime', 'durationMillis', 'date'],
        'request_headers'     => ['Accept-Locale', 'Accept-Language'],
        'required_if'         => { 'activityName' => ['manualCalories'] },
        'resources'           => ['user', '-', 'activities'],
      },
      'api-log-blood-pressure' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => ['systolic', 'diastolic', 'date'],
        'resources'           => ['user', '-', 'bp'],
      },
    }
  end

end
