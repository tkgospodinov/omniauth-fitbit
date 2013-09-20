module Fitbit
  class Api < OmniAuth::Strategies::Fitbit
    
    def api_call consumer_key, consumer_secret, params={'api-method'=>'nil'}, auth_token="", auth_secret=""
      api_params = get_lowercase_api_method(params)
      api_method = api_params['api-method']
      api_error = get_api_errors(api_params, api_method, auth_token, auth_secret)
      raise "#{api_method} " + api_error if api_error
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

    def get_api_errors params, api_method, auth_token="", auth_secret="" 
      required = @@fitbit_methods[api_method]
      params_keys = params.keys
      if required
        no_auth_tokens = true if (auth_token == "" or auth_secret == "")
        get_error_message(params_keys, api_method, required, no_auth_tokens)
      else
        "is not a valid Fitbit API method." 
      end
    end

    def get_error_message params_keys, api_method, required, no_auth_tokens
      if missing_url_parameters? required['url_parameters'], params_keys
        url_parameters_error(required['url_parameters'], params_keys)
      elsif required['post_parameters'] and missing_post_parameters? required['post_parameters'], params_keys
        post_parameters_error(required['post_parameters'], params_keys)
      elsif required['auth_required'] and no_auth_tokens
        auth_error(api_method, required['auth_required'], params_keys.include?('user-id'))
      end
    end

    def get_lowercase_api_method params
      params['api-method'] = params['api-method'].downcase
      params
    end

    def missing_url_parameters? required, params_keys
      url_parameters = get_url_parameters(required, params_keys)
      required and (url_parameters.is_a? Hash or params_keys & url_parameters != url_parameters)
    end

    def get_url_parameters required, params_keys
      if required.is_a? Hash
        required.keys.each do |x| 
          return required[x] if params_keys.include? x 
        end
      end
      required
    end

    def missing_post_parameters? required, supplied
      error = false
      required.each do |k,v|
        supplied_required = required[k] & supplied if k != 'required_if'
        case k
        when 'required'
          error = true if supplied_required != required[k]
        when 'exclusive'
          error = true if supplied_required.length != 1
        when 'one_required'
          error = true if supplied_required.length < 1
        when 'required_if'
          required[k].each do |k,v|
            error = true if supplied.include? k and !supplied.include? v
          end
        end
      end
      error
    end

    def url_parameters_error required, supplied
      if required.is_a? Hash
        count = 1
        error = "requires 1 of #{required.length} options: "
        required.keys.each do |x|
          error << "(#{count}) #{required[x]} "
          count += 1
        end
        error
      else
        "requires #{required}. You're missing #{required-supplied}."
      end
    end

    def post_parameters_error required, supplied
      error = nil
      required.keys.each do |k|
        supplied_required = required[k] & supplied if k != 'required_if'
        if k == 'required' and supplied_required != required[k]
          error = "requires POST parameters #{required[k]}. You're missing #{required[k]-supplied}."
        elsif k == 'exclusive' and supplied_required.length == 0
          error = "requires one of these POST parameters: #{required[k]}."
        elsif k == 'exclusive' and supplied_required.length != 1
          supplied_required_string = supplied_required.join(' AND ')
          error = "allows only one of these POST parameters #{required[k]}. You used #{supplied_required_string}."
        elsif k == 'one_required' and supplied_required.length == 0
          error = "requires at least one of the following POST parameters: #{required[k]}." 
        elsif k == 'required_if'
          required[k].each do |k,v|
            if supplied.include? k and !supplied.include? v
              error = "requires POST parameter #{v} when you use POST parameter #{k}."
            end
          end
        end
      end
      error
    end

    def auth_error api_method, auth_required, auth_supplied
      if auth_required.is_a? String
        "requires user auth_token and auth_secret, unless you include [\"user-id\"]." unless auth_supplied
      else
        "requires user auth_token and auth_secret."
      end
    end

    def build_request consumer_key, consumer_secret, auth_token, auth_secret
      fitbit = Fitbit::Api.new :fitbit, consumer_key, consumer_secret
      OAuth::AccessToken.new fitbit.consumer, auth_token, auth_secret
    end

    def send_api_request params, api_method, access_token
      fitbit = @@fitbit_methods[api_method]
      http_method = fitbit['http_method']
      request_url = build_url(params, fitbit, http_method)
      request_headers = get_request_headers(params, fitbit) if fitbit['request_headers']

      if http_method == 'get' or http_method == 'delete'
        access_token.request( http_method, "http://api.fitbit.com#{request_url}", request_headers )
      else
        access_token.request( http_method, "http://api.fitbit.com#{request_url}", "",  request_headers )
      end
    end

    def build_url params, fitbit, http_method
      api_version = @@api_version
      api_url_resources = get_url_resources(params, fitbit)
      api_format = get_response_format(params['response-format'])
      api_post_parameters = get_supplied_post_parameters(fitbit, params) if http_method == 'post'
      api_query = uri_encode_query(params['query'])

      "/#{api_version}/#{api_url_resources}.#{api_format}#{api_query}#{api_post_parameters}"
    end

    def get_supplied_post_parameters fitbit, params
      not_post_parameters = ['request_headers', 'url_parameters']
      ignore = ['api-method', 'response-format']
      not_post_parameters.each do |x|
        fitbit[x].each { |y| ignore.push(y) } if fitbit[x] 
      end
      post_parameters = params.select { |k,v| !ignore.include? k }

      "?" + OAuth::Helper.normalize(post_parameters)
    end
    
    def get_request_headers params, fitbit
      request_headers = fitbit['request_headers']
      available_headers = request_headers & params.keys
      params.select { |k,v| available_headers.include? k }
    end

    def get_url_resources params, fitbit
      params_keys = params.keys
      api_ids = get_url_parameters(fitbit['url_parameters'], params_keys) 
      api_resources = get_url_parameters(fitbit['resources'], params_keys)
      add_ids(fitbit['auth_required'], api_resources, api_ids, params)
    end

    def add_ids auth_required, api_resources, api_ids, params
      api_resources.each_with_index do |x, i|
        id = x.delete "<>"
        if api_ids and api_ids.include? id and !api_ids.include? x
          api_resources[i] = params[id]
          api_ids.delete(x)
        end
        if x == '-' and auth_required == 'user-id'
          api_resources[i] = params['user-id'] if params['user-id']
        end
      end
      api_resources.join("/")
    end

    def get_response_format api_format
      !api_format.nil? and api_format.downcase == 'json' ? 'json' : 'xml'
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
      'api-accept-invite' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['accept'],
        },
        'url_parameters'      => ['from-user-id'],
        'resources'           => ['user', '-', 'friends', 'invitations', '<from-user-id>'],
      },
      'api-add-favorite-activity' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'url_parameters'      => ['activity-id'],
        'resources'           => ['user', '-', 'activities', 'favorite', '<activity-id>'],
      },
      'api-add-favorite-food' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'url_parameters'      => ['food-id'],
        'resources'           => ['user', '-', 'foods', 'log', 'favorite', '<food-id>'],
      },
      'api-browse-activities' => {
        'auth_required'       => false,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['activities'],
      },
      'api-config-friends-leaderboard' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['hideMeFromLeaderboard'],
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'friends', 'leaderboard'],
      },
      'api-create-food' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['name', 'defaultFoodMeasurementUnitId', 'defaultServingSize', 'calories'],
        },
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['foods'],
      },
      'api-create-invite' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     =>  {
          'exlusive' => ['invitedUserEmail', 'invitedUserId'],
        },
        'resources'           => ['user', '-', 'friends', 'invitations'],
      },
      'api-delete-activity-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['activity-log-id'],
        'resources'           => ['user', '-', 'activities', '<activity-log-id>'],
      },
      'api-delete-blood-pressure-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['bp-log-id'],
        'resources'           => ['user', '-', 'bp', '<bp-log-id>'],
      },
      'api-delete-body-fat-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['body-fat-log-id'],
        'resources'           => ['user', '-', 'body', 'log', 'fat', '<body-fat-log-id>'],
      },
      'api-delete-body-weight-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['body-weight-log-id'],
        'resources'           => ['user', '-', 'body', 'log', 'weight', '<body-weight-log-id>'],
      },
      'api-delete-favorite-activity' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['activity-id'],
        'resources'           => ['user', '-', 'activities', 'favorite', '<activity-id>'],
      },
      'api-delete-favorite-food' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['food-id'],
        'resources'           => ['user', '-', 'foods', 'log', 'favorite', '<food-id>'],
      },
      'api-delete-food-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['food-log-id'],
        'resources'           => ['user', '-', 'foods', 'log', '<food-log-id>'],
      },
      'api-delete-heart-rate-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['heart-log-id'],
        'resources'           => ['user', '-', 'heart', '<heart-log-id>'],
      },
      'api-delete-sleep-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['sleep-log-id'],
        'resources'           => ['user', '-', 'sleep', '<sleep-log-id>'],
      },
      'api-delete-water-log' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['water-log-id'],
        'resources'           => ['user', '-', 'foods', 'log', 'water', '<water-log-id>'],
      },
      'api-devices-add-alarm' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['time', 'enabled', 'recurring', 'weekDays'],
        },
        'request_headers'     => ['Accept-Language'],
        'url_parameters'      => ['device-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms'],
      },
      'api-devices-delete-alarm' => {
        'auth_required'       => true,
        'http_method'         => 'delete',
        'url_parameters'      => ['device-id', 'alarm-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms', '<alarm-id>'],
      },
      'api-devices-get-alarms' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'url_parameters'      => ['device-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms'],
      },
      'api-devices-update-alarm' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['time', 'enabled', 'recurring', 'weekDays', 'snoozeLength', 'snoozeCount'],
        },
        'request_headers'     => ['Accept-Language'],
        'url_parameters'      => ['device-id', 'alarm-id'],
        'resources'           => ['user', '-', 'devices', 'tracker', '<device-id>', 'alarms', '<alarm-id>'],
      },
      'api-get-activities' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale', 'Accept-Language'],
        'url_parameters'      => ['date'],
        'resources'           => ['user', '-', 'activities', 'date', '<date>'],
      },
      'api-get-activity' => {
        'auth_required'       => false,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'url_parameters'      => ['activity-id'],
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
        'url_parameters'      => ['date'],
        'resources'           => ['user', '-', 'bp', 'date', '<date>'],
      },
      'api-get-body-fat' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'url_parameters'      => {
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
        'url_parameters'      => ['date'],
        'resources'           => ['user', '-', 'body', 'date', '<date>'],
      },
      'api-get-body-weight' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'url_parameters'      => {
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
        'url_parameters'      => ['device-id'],
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
        'url_parameters'      => ['food-id'],
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
        'url_parameters'      => ['date'],
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
        'url_parameters'      => ['date'],
        'resources'           => ['user', '-', 'glucose', 'date', '<date>'],
      },
      'api-get-heart-rate' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'url_parameters'      => ['date'],
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
        'url_parameters'      => ['date'],
        'resources'           => ['user', '-', 'sleep', 'date', '<date>'],
      },
      'api-get-time-series' => {
        'auth_required'       => 'user-id',
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Language'],
        'url_parameters'      => {
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
        'url_parameters'      => ['date'],
        'resources'           => ['user', '-', 'foods', 'log', 'water', 'date', '<date>'],
      },
      'api-log-activity' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'exclusive' => ['activityId', 'activityName'], 
          'required'  => ['startTime', 'durationMillis', 'date'],
          'required_if'  => { 'activityName' => 'manualCalories' },
        },
        'request_headers'     => ['Accept-Locale', 'Accept-Language'],
        'resources'           => ['user', '-', 'activities'],
      },
      'api-log-blood-pressure' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['systolic', 'diastolic', 'date'],
        },
        'resources'           => ['user', '-', 'bp'],
      },
      'api-log-body-fat' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['fat', 'date'],
        },
        'resources'           => ['user', '-', 'body', 'log', 'fat'],
      },
      'api-log-body-measurements' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['date'],
          'one_required' => ['bicep','calf','chest','fat','forearm','hips','neck','thigh','waist','weight'],
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'body'],
      },
      'api-log-body-weight' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['weight', 'date'],
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'body', 'log', 'weight'],
      },
      'api-log-food' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'exclusive' => ['foodId', 'foodName'], 
          'required'  => ['mealTypeId', 'unitId', 'amount', 'date'],
        },
        'request_headers'     => ['Accept-Locale'],
        'resources'           => ['user', '-', 'foods', 'log'],
      },
      'api-log-glucose' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'exclusive' => ['hbac1c', 'tracker'], 
          'required'  => ['date'],
          'required_if'  => { 'tracker' => 'glucose' },
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'glucose'],
      },
      'api-log-heart-rate' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['tracker', 'heartRate', 'date'],
        },
        'resources'           => ['user', '-', 'heart'],
      },
      'api-log-sleep' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['startTime', 'duration', 'date'],
        },
        'resources'           => ['user', '-', 'sleep'],
      },
      'api-log-water' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['amount', 'date'],
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'foods', 'log', 'water'],
      },
      'api-search-foods' => {
        'auth_required'       => true,
        'http_method'         => 'get',
        'request_headers'     => ['Accept-Locale'],
        'url_parameters'      => ['query'],
        'resources'           => ['foods', 'search'],
      },
      'api-update-activity-daily-goals' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'one_required' => ['caloriesOut','activeMinutes','floors','distance','steps'],
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'activities', 'goals', 'daily'],
      },
      'api-update-activity-weekly-goals' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'one_required' => ['steps','distance','floors'],
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'activities', 'goals', 'weekly'],
      },
      'api-update-fat-goal' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['fat'],
        },
        'resources'           => ['user', '-', 'body', 'log', 'fat', 'goal'],
      },
      'api-update-food-goals' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'exclusive' => ['calories', 'intensity'],
        },
        'request_headers'     => ['Accept-Locale', 'Accept-Language'],
        'resources'           => ['user', '-', 'foods', 'log', 'goal'],
      },
      'api-update-user-info' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'one_required' => [
          'gender','birthday','height','nickname','aboutMe','fullname','country','state','city',
          'strideLengthWalking','strideLengthRunning','weightUnit','heightUnit','waterUnit','glucoseUnit',
          'timezone','foodsLocale','locale','localeLang','localeCountry'
          ],
        },
        'request_headers'     => ['Accept-Language'],
        'resources'           => ['user', '-', 'profile'],
      },
      'api-update-weight-goal' => {
        'auth_required'       => true,
        'http_method'         => 'post',
        'post_parameters'     => {
          'required' => ['startDate', 'startWeight'],
        },
        'resources'           => ['user', '-', 'body', 'log', 'weight', 'goal'],
      },
    }
  end

end
