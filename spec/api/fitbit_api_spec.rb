require 'spec_helper'

describe Fitbit::Api do
  subject do
    Fitbit::Api.new({})
  end

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
      subject.get_resource_paths.sample
    when :time
      current_time = Time.now
      current_time.strftime('%H:%M').squeeze(' ')
    when :token
      length = 30
      rand(36**length).to_s(36)
    end
  end

  def helpful_errors api_method, data_type, supplied
    required = get_required_data(api_method, data_type)
    required_data = get_url_parameters(required, supplied)
    exclusive_data = get_exclusive_data(api_method, 'post_parameters')
    case data_type
    when 'post_parameters'
      required = get_required_data(api_method, 'post_parameters')
      required_data = get_required_post_parameters(required, 'required')
      error = get_required_post_parameters_error(required_data, 'required', supplied)
      "#{api_method} " + error
    when 'required_exclusive_post_parameters'
      required = get_required_data(api_method, 'post_parameters')
      exclusive_data = get_required_post_parameters(required, 'exclusive')
      error = get_required_post_parameters_error(exclusive_data, 'exclusive_not_enough', supplied)
      "#{api_method} " + error
    when 'exclusive_post_parameters'
      required = get_required_data(api_method, 'post_parameters')
      exclusive_data = get_required_post_parameters(required, 'exclusive')
      error = get_required_post_parameters_error(exclusive_data, 'exclusive_too_many', supplied)
      "#{api_method} " + error
    when 'required_if'
      required = get_required_data(api_method, 'post_parameters')
      exclusive_data = get_required_post_parameters(required, 'required_if')
      error = get_required_post_parameters_error(exclusive_data, 'required_if', supplied)
      "#{api_method} " + error
    when 'one_required'
      required = get_required_data(api_method, 'post_parameters')
      exclusive_data = get_required_post_parameters(required, 'one_required')
      error = get_required_post_parameters_error(exclusive_data, 'one_required', supplied)
      "#{api_method} " + error
    when 'url_parameters'
      get_url_parameters_error(api_method, required, required_data, supplied)
    when 'resource_path'
      get_resource_path_error(supplied)
    else
      "#{api_method} is not a valid api method."
    end
  end

  def get_required_data api_method, data_type
    @fitbit_methods[api_method][data_type] if @fitbit_methods[api_method]
  end

  def get_required_post_parameters required, type
    required[type]
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
      error = "#{api_method} is not a valid API method OR does not have any required parameters."
    elsif required.is_a? Hash
      count = 1
      error = "#{api_method} requires 1 of #{required.length} options: "
      required.keys.each do |x|
        error << "(#{count}) #{required[x]} "
        count += 1
      end
    else
      error = "#{api_method} requires #{required_data}. You're missing #{required-supplied}."
    end
    error
  end

  def get_resource_path_error supplied
    resource_path = supplied['resource-path']
    fitbit_resource_paths = subject.get_resource_paths
    if resource_path and !fitbit_resource_paths.include? resource_path
      "#{resource_path} is not a valid Fitbit api-get-time-series resource-path."
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


  before(:all) do
    @params = {}
    @consumer_key = random_data(:token)
    @consumer_secret = random_data(:token)
    @auth_token = random_data(:token)
    @auth_secret = random_data(:token)
    @fitbit_methods = subject.get_fitbit_methods
    
    #generate useful random data for tests
    @activity_id = random_data(:fitbit_id)
    @activity_log_id = random_data(:fitbit_id)
    @activity_name = random_data(:activity_name)
    @alarm_id = random_data(:fitbit_id)
    @body_fat_log_id = random_data(:fitbit_id)
    @body_weight_log_id = random_data(:fitbit_id)
    @bp_log_id = random_data(:fitbit_id)
    @date = random_data(:fixed_date)
    @date_range = random_data(:date_range)
    @device_id = random_data(:fitbit_id)
    @food_id = random_data(:fitbit_id)
    @food_log_id = random_data(:fitbit_id)
    @heart_log_id = random_data(:fitbit_id)
    @period = random_data(:period)
    @resource_path = random_data(:resource_path)
    @sleep_log_id = random_data(:fitbit_id)
    @time = random_data(:time)
    @user_id = random_data(:fitbit_id)
    @water_log_id = random_data(:fitbit_id)
  end

  before(:each) do
    @response_format = random_data(:response_format)
  end

  context 'Invalid Fitbit API method' do
    before(:each) do
      @params = { 
        'api-method'          => 'API-Search-Fudd',
        'response-format'     => @response_format,
      }
    end
    it 'Raises Error: <api-method> is not a valid Fitbit API method' do
      error_message = "#{@params['api-method'].downcase} is not a valid Fitbit API method."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing response-format' do
    it 'Defaults to xml response-format' do
      @api_method = 'API-Search-Foods'
      @api_url = "/1/foods/search.xml?query=banana%20cream%20pie"
      @params = { 
        'api-method'      => 'API-Search-Foods',
        'query'           => 'banana cream pie',
      }

      oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end

  context 'Missing required URL parameters' do
    before(:each) do
      @api_method = 'api-delete-activity-log'
      @api_url = "/1/user/-/activities/#{@activity_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Activity-Log',
        'activity-log-id' => @activity_log_id, 
        'response-format'     => @response_format,
      }
    end

    it 'Raises Error: <api-method> requires <required>. You\'re missing <required-supplied>.' do
      @params.delete('activity-log-id')
      error_message = helpful_errors(@api_method, 'url_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing required auth tokens or user-id' do
    it 'Raises Error: <api-method> requires user auth_token and auth_secret' do
      @api_method = 'api-accept-invite'
      @api_url = "/1/user/-/friends/invitations/#{@user_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Accept-Invite',
        'accept'              => 'true',
        'from-user-id'        => @user_id,
        'response-format'     => @response_format,
      }
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it "Raises Error: <api-method> requires user auth_token and auth_secret, unless you include [\"user-id\"]." do
      @api_method = 'api-get-badges' 
      @api_url = "/1/user/-/badges.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Badges',
        'Accept-Locale'   => 'en_US',
        'response-format'     => @response_format,
      }
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing required POST parameters' do
    before(:each) do
      @api_method = 'api-accept-invite'
      @api_url = "/1/user/-/friends/invitations/#{@user_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Accept-Invite',
        'from-user-id'        => @user_id,
        'response-format'     => @response_format,
      }
    end

    it 'Raises Error: <api-method> requires POST parameters <required>, You\'re missing <required-supplied>.' do
      error_message = helpful_errors(@api_method, 'post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing required optional POST parameters (where using one parameter requires using another related parameter)' do
    before(:each) do
      @api_method = 'api-log-activity'
      @api_url = "/1/user/-/activities.#{@response_format}"
      @params = {
        'api-method'          => 'API-Log-Activity',
        'activityId'          => @activity_id,
        'startTime'           => @time,
        'durationMillis'      => '10000',
        'date'                => @date,
        'response-format'     => @response_format,
      }
    end

    it 'Raises Error: <api-method> requires <missing_parameter> when you use <current_parameter>.' do
      @params.delete('activityId')
      @params['activityName'] = @activity_name
      error_message = helpful_errors(@api_method, 'required_if', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing one_required POST parameter (where at least one of these parameters must be used)' do
    before(:each) do
      @api_method = 'api-log-body-measurements'
      @api_url = "/1/user/-/body.#{@response_format}"
      @params = {
        'api-method'          => 'API-Log-Body-Measurements',
        'bicep'               => '1.00',
        'date'                => @date,
        'response-format'     => @response_format,
      }
    end

    it 'Raises Error: <api-method> requires at least one of the following POST parameters <one_required>.' do
      @params.delete('bicep')
      error_message = helpful_errors(@api_method, 'one_required', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Exclusive required POST parameters (where one, and only one, of these parameters must be used)' do
    before(:each) do
      @api_method = 'api-log-activity'
      @api_url = "/1/user/-/activities.#{@response_format}"
      @params = {
        'api-method'          => 'API-Log-Activity',
        'activityId'          => @activity_id,
        'startTime'           => @time,
        'durationMillis'      => '10000',
        'date'                => @date,
        'response-format'     => @response_format,
      }
    end

    context 'When more than one exclusive parameter is included' do
      it 'Raises Error: <api-method> allows only one of these POST parameters: <exclusive>. You used <supplied>.' do
        @params['activityName'] = @activity_name
        @params['manualCalories'] = '1000'
        error_message = helpful_errors(@api_method, 'exclusive_post_parameters', @params.keys)
        lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
      end
    end

    context 'When none of the exclusive parameters are included' do
      it 'Raises Error: <api-method> requires one of these POST parameters: <exclusive>.' do
        @params.delete('activityId')
        error_message = helpful_errors(@api_method, 'required_exclusive_post_parameters', @params.keys)
        lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
      end
    end
  end
  
  context 'Create authenticated GET request' do
    before(:each) do
      @api_method = 'api-browse-activities'
      @api_url = "/1/activities.#{@response_format}"
      @params = { 
        'api-method'        => 'API-Browse-Activities',
        'Accept-Locale'     => 'en_US', 
        'response-format'   => @response_format,
      }
    end

    it 'GET request' do
      @params.delete('Accept-Locale')
      oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'GET request with request headers' do
      headers = { 'Accept-Locale' => 'en_US' }
      stub_request(:get, "api.fitbit.com#{@api_url}") do |req|
        headers.each_pair do |k,v|
          req.headers[k] = v
        end
      end 
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'GET request with dynamic url parameter' do
      @api_method = 'api-devices-get-alarms' 
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms.#{@response_format}"
      @params = {
        'api-method'    => 'API-Devices-Get-Alarms',
        'device-id'     => @device_id,
        'response-format'     => @response_format,
      }
      oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'GET request with user-id authentication instead of auth tokens' do
      @api_method = 'api-get-activity-stats' 
      @api_url = "/1/user/#{@user_id}/activities.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Activity-Stats',
        'Accept-Language' => 'en_US',
        'response-format'     => @response_format,
      }
      @params['user-id'] = @user_id
      oauth_unauthenticated :get, @api_url, @consumer_key, @consumer_secret, @params
    end

    context 'GET request with multiple possible urls based on date or time period' do
      before(:each) do
        @params = {}
        @api_method = 'api-get-body-fat'
        @api_url = "/1/user/-/body/log/fat/date/#{@date}.#{@response_format}"
        @params = {
          'api-method'      => 'API-Get-Body-Fat',
          'date'            => @date,
          'response-format'     => @response_format,
        }
      end

      it 'Request based on <date>' do
        oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
      end

      it 'Request based on <base-date>/<end-date>' do
        @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@date_range[1]}.#{@response_format}"
        @params.delete('date')
        @params['base-date'] = @date_range[0]
        @params['end-date'] = @date_range[1]
        oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
      end

      it 'Request based on <base-date>/<period>' do
        @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@period}.#{@response_format}"
        @params.delete('date')
        @params['base-date'] = @date_range[0]
        @params['period'] = @period
        oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
      end
    end

    it 'GET request with search query' do
      @api_method = 'API-Search-Foods'
      @api_url = "/1/foods/search.#{@response_format}?query=banana%20cream%20pie"
      @params = { 
        'api-method'      => 'API-Search-Foods',
        'query'           => 'banana cream pie',
        'response-format' => @response_format,
      }

      oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end

  context 'Create authenticated POST request' do
    it 'POST request with request headers' do
      @api_method = 'api-config-friends-leaderboard'
      @api_url = "/1/user/-/friends/leaderboard.#{@response_format}"
      @params = {
        'api-method'            => 'API-Config-Friends-Leaderboard',
        'hideMeFromLeaderboard' => 'true',
        'Accept-Language'       => 'en_US',
        'response-format'     => @response_format,
      }
      ignore = ['api-method', 'response-format', 'Accept-Language']
      @api_url = get_url_with_post_parameters(@api_url, @params.dup, ignore)

      headers = { 'Accept-Language' => 'en_US' }
      stub_request(:post, "api.fitbit.com#{@api_url}") do |req|
        headers.each_pair do |k,v|
          req.headers[k] = v
        end
      end 
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'POST request with dynamic url parameter and one required POST parameter' do
      @api_method = 'api-accept-invite'
      @api_url = "/1/user/-/friends/invitations/#{@user_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Accept-Invite',
        'accept'              => 'true',
        'from-user-id'        => @user_id,
        'response-format'     => @response_format,
      }
      ignore = ['api-method', 'response-format', 'from-user-id']
      @api_url = get_url_with_post_parameters(@api_url, @params.dup, ignore)
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'POST request with dynamic url parameters and multiple optional POST parameters' do
      @api_method = 'api-devices-update-alarm' 
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms/#{@alarm_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Devices-Update-Alarm',
        'device-id'       => @device_id,
        'alarm-id'        => @alarm_id,
        'time'            => '10:00',
        'enabled'         => 'true',
        'recurring'       => 'true',
        'weekDays'        => '(MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY)',
        'label'           => 'test alarm',
        'snoozeLength'    => '10',
        'snoozeCount'     => '2',
        'vibe'            => 'DEFAULT',
        'Accept-Language' => 'en_US', 
        'response-format'     => @response_format,
      }
      ignore = ['api-method', 'response-format', 'Accept-Language', 'device-id', 'alarm-id']
      @api_url = get_url_with_post_parameters(@api_url, @params.dup, ignore)
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end

  context 'Create authenticated DELETE request' do
    it 'DELETE request with dynamic url parameter' do
      @api_method = 'api-delete-activity-log'
      @api_url = "/1/user/-/activities/#{@activity_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Activity-Log',
        'activity-log-id' => @activity_log_id, 
        'response-format'     => @response_format,
      }
      oauth_authenticated :delete, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'DELETE request with multiple dynamic url parameters' do
      @api_method = 'api-devices-delete-alarm' 
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms/#{@alarm_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Devices-Delete-Alarm',
        'device-id'           => @device_id,
        'alarm-id'            => @alarm_id,
        'response-format'     => @response_format,
      }
      oauth_authenticated :delete, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end

  context 'API-Get-Time-Series method' do
    before(:each) do
      @api_method = 'api-get-time-series' 
      @api_url = "/1/user/-/#{@resource_path}/date/#{@date_range[0]}/#{@date_range[1]}.#{@response_format}"
      @params = {
        'api-method'            => 'API-Get-Time-Series',
        'response-format'       => @response_format,
        'base-date' => @date_range[0],
        'end-date'  => @date_range[1],
        'period'    => @period,
        'resource-path' => @resource_path,
      }
    end

    it 'should create API-Get-Time-Series <base-date>/<end-date> OAuth request' do
      @params.delete('period')
      oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'should create API-Get-Time-Series <base-date>/<period> OAuth request' do
      @params.delete('end-date')
      @api_url = "/1/user/-/#{@resource_path}/date/#{@date_range[0]}/#{@period}.#{@response_format}"
      oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'should create API-Get-Time-Series <base-date>/<period> OAuth request with user-id instead of auth tokens' do
      @params.delete('end-date')
      @params['user-id'] = @user_id
      @api_url = "/1/user/#{@user_id}/#{@resource_path}/date/#{@date_range[0]}/#{@period}.#{@response_format}"
      oauth_unauthenticated :get, @api_url, @consumer_key, @consumer_secret, @params
    end
  end

  context 'API-Create-Subscription method' do
      let(:params) {
        {
          'api-method'        => 'API-Create-Subscription',
          'collection-path'   => '',
          'subscription-id'   => '550',
          'response-format'   => @response_format,
        }
      }

    it "Create a subscription to user's activities." do
      @api_url = "/1/user/-/food/apiSubscriptions/550-food.#{@response_format}"
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, params, @auth_token, @auth_secret
    end

    it "Create a subscription to all of a user's changes" do
      @api_url = "/1/user/-/apiSubscriptions/550.#{@response_format}"
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, params, @auth_token, @auth_secret
    end
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
