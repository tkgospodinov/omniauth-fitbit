module FitbitApiHelper
  def random_data data_type
    case data_type
    when :activity_name
      ['biking', 'jogging', 'yoga', 'jazzercise'].sample
    when :date_range
      base_date = Date.today
      end_date = base_date + rand(365)
      [base_date, end_date].map { |day| day.strftime('%y-%m-%d').squeeze(' ') }
    when :fitbit_id
      length = 7
      ([*('A'..'Z'),*('0'..'9')]-%w(0 1 I O)).sample(length).join
    when :fixed_date
      today = Date.today
      today.strftime('%Y-%m-%d').squeeze(' ')
    when :period
      number_of = rand(31)
      types = ['d', 'w', 'm']
      [number_of, types.sample(1)].join
    when :response_format
      random_format = ['json', 'xml'].sample
    when :resource_path
      resource_paths = [
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
      resource_paths.sample
    when :time
      current_time = Time.now
      current_time.strftime('%H:%M').squeeze(' ')
    when :token
      length = 30
      rand(36**length).to_s(36)
    end
  end

  def helpful_errors supplied_api_method, error_type, supplied
    api_method = supplied_api_method.downcase
    required = get_required_data(api_method, error_type)
    required_data = get_required_post_parameters(required, error_type)

    case error_type
    when 'post_parameters'
      error = get_required_post_parameters_error(required_data, 'required', supplied)
    when 'exclusive_too_many'
      error = get_required_post_parameters_error(required_data, 'exclusive_not_enough', supplied)
    when 'exclusive_too_few'
      error = get_required_post_parameters_error(required_data, 'exclusive_too_many', supplied)
    when 'required_if'
      error = get_required_post_parameters_error(required_data, 'required_if', supplied)
    when 'one_required'
      error = get_required_post_parameters_error(required_data, 'one_required', supplied)
    when 'url_parameters'
      required_data = get_url_parameters(required, supplied)
      error = get_url_parameters_error(api_method, required, required_data, supplied)
    when 'resource_path'
      error = get_resource_path_error(supplied)
    else
      error = "is not a valid api method."
    end
    "#{api_method} " + error
  end

  def get_required_data api_method, error_type
    data_type = 'post_parameters' unless error_type == 'url_parameters' or error_type == 'resource_path'
    data_type ||= error_type
    fitbit_methods = subject.get_fitbit_methods
    fitbit_methods[api_method][data_type] if fitbit_methods[api_method]
  end

  def get_resource_paths
    fitbit_resource_paths = subject.get_resource_paths
  end

  def get_required_post_parameters required, error_type
    if error_type == 'url_parameters'
      nil
    elsif error_type == 'post_parameters'
      required['required']
    elsif error_type == 'exclusive_too_many' or error_type == 'exclusive_too_few'
      required['exclusive']
    else
      required[error_type]
    end
  end

  def get_required_post_parameters_error required, required_type, supplied
    case required_type
    when 'required'
      missing_data = required - supplied
      "requires POST parameters #{required}. You're missing #{missing_data}."
    when 'exclusive_too_many'
      extra_data = get_extra_data(required)
      "allows only one of these POST parameters #{required}. You used #{extra_data}."
    when 'exclusive_not_enough'
      "requires one of these POST parameters: #{required}."
    when 'one_required'
      "requires at least one of the following POST parameters: #{required}."
    when 'required_if'
      required.each do |k,v|
        if supplied.include? k and !supplied.include? v
          return "requires POST parameter #{v} when you use POST parameter #{k}."
        end
      end
    end
  end

  def get_url_parameters required, supplied
    if required.is_a? Hash
      required.keys.each do |x|
        return required[x] if supplied.include? x
      end
    end
    required
  end

  def get_url_parameters_error api_method, required, required_data, supplied
    if required.nil?
      error = "is not a valid API method OR does not have any required parameters."
    elsif required.is_a? Hash
      count = 1
      error = "requires 1 of #{required.length} options: "
      required.keys.each do |x|
        error << "(#{count}) #{required[x]} "
        count += 1
      end
    else
      error = "requires #{required_data}. You're missing #{required-supplied}."
    end
    error
  end

  def get_resource_path_error supplied
    resource_path = supplied['resource-path']
    fitbit_resource_paths = subject.get_resource_paths
    if resource_path and !fitbit_resource_paths.include? resource_path
      "is not a valid Fitbit api-get-time-series resource-path."
    end
  end

  def get_exclusive_data api_method, data_type
    post_parameters = get_required_data(api_method, data_type)
    exclusive_post_parameters = post_parameters.select { |x| x.is_a? Array } if post_parameters
    exclusive_post_parameters.flatten if exclusive_post_parameters
  end

  def get_extra_data exclusive_data
    exclusive_data.join(' AND ')
  end
    
  def oauth_unauthenticated http_method, api_url, consumer_key, consumer_secret, params
    stub_request(http_method, "api.fitbit.com#{api_url}")
    api_call = subject.api_call(consumer_key, consumer_secret, params)
    expect(api_call.class).to eq(Net::HTTPOK)
  end
    
  def oauth_authenticated http_method, api_url, consumer_key, consumer_secret, params, auth_token, auth_secret
    stub_request(http_method, "api.fitbit.com#{api_url}")
    api_call = subject.api_call(consumer_key, consumer_secret, params, auth_token, auth_secret)
    expect(api_call.class).to eq(Net::HTTPOK)
  end

  def get_url_with_post_parameters url, params, ignore
    params.keys.each { |k| params.delete(k) if ignore.include? k } 
    url + "?" + OAuth::Helper.normalize(params)
  end
end
