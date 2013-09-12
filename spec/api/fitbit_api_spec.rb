require 'spec_helper'

describe Fitbit::Api do
  subject do
    Fitbit::Api.new({})
  end

  def random_data data_type
    case data_type
    when :token
      length = 30
      rand(36**length).to_s(36)
    when :fitbit_id
      length = 7
      ([*('A'..'Z'),*('0'..'9')]-%w(0 1 I O)).sample(length).join
    when :fixed_date
      today = Date.today
      DateTime.strptime(today.to_s, '%Y-%m-%d').to_s
    when :date_range
      base_date = Date.today
      end_date = base_date + rand(365)
      [base_date, end_date].map { |day| day.strftime('%y-%m-%d').squeeze(' ') }
    when :period
      number_of = rand(31)
      types = ['d', 'w', 'm']
      [number_of, types.sample(1)].join
    when :response_format
      random_format = ['json', 'xml'].sample
    end
  end

  def helpful_errors api_method, data_type, supplied
    required = get_required_data(api_method, data_type)
    required_data = get_required_parameters(required, supplied)
    missing_data = delete_required_data(required_data, data_type)
    case data_type
    when 'post_parameters'
      "#{api_method} requires POST Parameters #{required_data}. You're missing #{missing_data}."
    when 'exclusive_post_parameters'
      exclusive_data = get_exclusive_data(api_method, 'post_parameters')
      extra_data = get_extra_data(exclusive_data)
      "#{api_method} allows only one of these POST Parameters #{exclusive_data}. You used #{extra_data}."
    when 'required_parameters'
      get_required_parameters_error(api_method, required, required_data, missing_data)
    else
      "#{api_method} is not a valid error type."
    end
  end

  def get_required_data api_method, data_type
    @fitbit_methods[api_method][data_type]
  end

  def get_required_parameters required, supplied
    if required.is_a? Hash
      required.keys.each do |x|
        return required[x] if supplied.include? x
      end
    end
    required
  end

  def get_required_parameters_error api_method, required, required_data, missing_data
    if required.is_a? Hash
      count = 1
      error = "#{api_method} requires 1 of #{required.length} options: "
      required.keys.each do |x|
        error << "(#{count}) #{required[x]} "
        count += 1
      end
    else
      error = "#{api_method} requires #{required_data}. You're missing #{missing_data}."
    end
    error
  end

  def get_exclusive_data api_method, data_type
    post_parameters = get_required_data(api_method, data_type)
    exclusive_post_parameters = post_parameters.select { |x| x.is_a? Array } if post_parameters
    exclusive_post_parameters.flatten if exclusive_post_parameters
  end

  def delete_required_data required_data, data_type
    if data_type == 'required_parameters'
      required_data.each { |parameter| @params.delete(parameter) }
    elsif data_type == 'post_parameters'
      required_data.each { |parameter| @params.delete(parameter) unless parameter.is_a? Array }
    end
  end

  def get_extra_data exclusive_data
    extra_data = exclusive_data.each { |exclusive| @params[exclusive] = 'cheese' } if exclusive_data
    extra_data.map { |data| "'#{data}'" }.join(' AND ')
  end

  before(:all) do
    @consumer_key = random_data(:token)
    @consumer_secret = random_data(:token)
    @auth_token = random_data(:token)
    @auth_secret = random_data(:token)
    @fitbit_methods = subject.get_fitbit_methods
    
    #generate useful random data for tests
    @activity_id = random_data(:fitbit_id)
    @activity_log_id = random_data(:fitbit_id)
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
    @sleep_log_id = random_data(:fitbit_id)
    @user_id = random_data(:fitbit_id)
    @water_log_id = random_data(:fitbit_id)
  end

  before(:each) do
    @response_format = random_data(:response_format)
  end

  context 'invalid Fitbit API method' do
    before(:each) do
      @params = { 
        'api-method'          => 'API-Search-Fudd',
        'response-format'     => @response_format,
      }
    end
    it 'should return a helpful error' do
      error_message = "#{@params['api-method'].downcase} is not a valid Fitbit API method."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Accept-Invite method' do
    before(:each) do
      @api_method = 'api-accept-invite'
      @api_url = "/1/user/-/friends/invitations/#{@user_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Accept-Invite',
        'accept'              => 'true',
        'from-user-id'        => @user_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Accept-Invite url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Accept-Invite OAuth request' do
      stub_request(:post, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      error_message = helpful_errors(@api_method, 'post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Add-Favorite-Activity method' do
    before(:each) do
      @api_method = 'api-add-favorite-activity' 
      @api_url = "/1/user/-/activities/favorite/#{@activity_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Add-Favorite-Activity',
        'activity-id'     => @activity_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Add-Favorite-Activity url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Add-Favorite-Activity OAuth request' do
      stub_request(:post, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Add-Favorite-Food method' do
    before(:each) do
      @api_method = 'api-add-favorite-food'
      @api_url = "/1/user/-/foods/log/favorite/#{@food_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Add-Favorite-Food',
        'food-id'         => @food_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Add-Favorite-Food url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Add-Favorite-Food OAuth request' do
      stub_request(:post, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end
  
  context 'API-Browse-Activites method' do
    before(:each) do
      @api_method = 'api-browse-activites'
      @api_url = "/1/activities.#{@response_format}"
      @params = { 
        'api-method'        => 'API-Browse-Activites',
        'Accept-Locale' => 'en_US', 
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Browse-Activites url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Browse-Activites OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end
  end

  context 'API-Config-Friends-Leaderboard method' do
    before(:each) do
      @api_method = 'api-config-friends-leaderboard'
      @api_url = "/1/user/-/friends/leaderboard.#{@response_format}"
      @params = {
        'api-method'            => 'API-Config-Friends-Leaderboard',
        'hideMeFromLeaderboard' => 'true',
        'Accept-Language'       => 'en_US',
        'response-format'     => @response_format,
      }
      
    end

    it 'should create API-Config-Friends-Leaderboard url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Config-Friends-Leaderboard OAuth request w/ _request headers_' do
      headers = { 'Accept-Language' => 'en_US' }
      stub_request(:post, "api.fitbit.com#{@api_url}") do |req|
        headers.each_pair do |k,v|
          req.headers[k] = v
        end
      end 
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      error_message = helpful_errors(@api_method, 'post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end
  
  context 'API-Create-Food method' do
    before(:each) do
      @api_method = 'api-create-food'
      @api_url = "/1/foods.#{@response_format}"
      @params = {
        'api-method'                    => 'API-Create-Food',
        'name'                          => 'food name',
        'defaultFoodMeasurementUnitId'  => '1',
        'defaultServingSize'            => '1',
        'calories'                      => '1000',
        'formType'                      => 'LIQUID',
        'description'                   => 'Say something here about the new food',
        'Accept-Locale'                 => 'en_US', 
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Create-Food url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Create-Food OAuth request' do
      stub_request(:post, "api.fitbit.com#{@api_url}") do |req|
        headers.each_pair do |k,v|
          req.headers[k] = v
        end
      end 
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      error_message = helpful_errors(@api_method, 'post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end
  
  context 'API-Create-Invite method' do
    before(:each) do
      @api_method = 'api-create-invite'
      @api_url = "/1/user/-/friends/invitations.#{@response_format}"
      @params = {
        'api-method'          => 'API-Create-Invite',
        'invitedUserEmail'    => 'email@email.com',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Create-Invite url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Create-Invite OAuth request' do
      stub_request(:post, "api.fitbit.com#{@api_url}") do |req|
        headers.each_pair do |k,v|
          req.headers[k] = v
        end
      end 
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if both _invitedUserEmail_ and _invitedUserId_ exclusive POST Parameters are used' do
      error_message = helpful_errors(@api_method, 'exclusive_post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Activity-Log method' do
    before(:each) do
      @api_method = 'api-delete-activity-log'
      @api_url = "/1/user/-/activities/#{@activity_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Activity-Log',
        'activity-log-id' => @activity_log_id, 
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Activity-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Activity-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Blood-Pressure-Log method' do
    before(:each) do
      @api_method = 'api-delete-blood-pressure-log'
      @api_url = "/1/user/-/bp/#{@bp_log_id}.#{@response_format}"
      @params = {
        'api-method'    => 'API-Delete-Blood-Pressure-Log',
        'bp-log-id'     => @bp_log_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Blood-Pressure-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Blood-Pressure-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Body-Fat-Log method' do
    before(:each) do
      @api_method = 'api-delete-body-fat-log'
      @api_url = "/1/user/-/body/log/fat/#{@body_fat_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Body-Fat-Log',
        'body-fat-log-id' => @body_fat_log_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Body-Fat-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Body-Fat-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Body-Weight-Log method' do
    before(:each) do
      @api_method = 'api-delete-body-weight-log'
      @api_url = "/1/user/-/body/log/weight/#{@body_weight_log_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Delete-Body-Weight-Log',
        'body-weight-log-id'  => @body_weight_log_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Body-Weight-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Body-Weight-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Favorite-Activity method' do
    before(:each) do
      @api_method = 'api-delete-favorite-activity' 
      @api_url = "/1/user/-/activities/favorite/#{@activity_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Favorite-Activity',
        'activity-id'     => @activity_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Favorite-Activity url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Favorite-Activity OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Favorite-Food method' do
    before(:each) do
      @api_method = 'api-delete-favorite-food'
      @api_url = "/1/user/-/foods/log/favorite/#{@food_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Favorite-Food',
        'food-id'         => @food_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Favorite-Food url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Favorite-Food OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Food-Log method' do
    before(:each) do
      @api_method = 'api-delete-food-log'
      @api_url = "/1/user/-/foods/log/#{@food_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Food-Log',
        'food-log-id'     => @food_log_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Food-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Food-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Heart-Rate-Log method' do
    before(:each) do
      @api_method = 'api-delete-heart-rate-log'
      @api_url = "/1/user/-/heart/#{@heart_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Heart-Rate-Log',
        'heart-log-id'    => @heart_log_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Heart-Rate-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Heart-Rate-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Sleep-Log method' do
    before(:each) do
      @api_method = 'api-delete-sleep-log'
      @api_url = "/1/user/-/sleep/#{@sleep_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Sleep-Log',
        'sleep-log-id'    => @sleep_log_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Sleep-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Sleep-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Delete-Water-Log method' do
    before(:each) do
      @api_method = 'api-delete-water-log'
      @api_url = "/1/user/-/foods/log/water/#{@water_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Water-Log',
        'water-log-id'    => @water_log_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Delete-Water-Log url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Delete-Water-Log OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Devices-Add-Alarm method' do
    before(:each) do
      @api_method = 'api-devices-add-alarm' 
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms.#{@response_format}"
      @params = {
        'api-method'      => 'API-Devices-Add-Alarm',
        'device-id'       => @device_id,
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
    end

    it 'should create API-Devices-Add-Alarm url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Devices-Add-Alarm OAuth request' do
      stub_request(:post, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      error_message = helpful_errors(@api_method, 'post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Devices-Delete-Alarm method' do
    before(:each) do
      @api_method = 'api-devices-delete-alarm' 
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms/#{@alarm_id}.#{@response_format}"
      @params = {
        'api-method'    => 'API-Devices-Delete-Alarm',
        'device-id'     => @device_id,
        'alarm-id'      => @alarm_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Devices-Delete-Alarm url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Devices-Delete-Alarm OAuth request' do
      stub_request(:delete, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Devices-Get-Alarms method' do
    before(:each) do
      @api_method = 'api-devices-get-alarms' 
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms.#{@response_format}"
      @params = {
        'api-method'    => 'API-Devices-Get-Alarms',
        'device-id'     => @device_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Devices-Get-Alarms url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Devices-Get-Alarms OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Devices-Update-Alarm method' do
    before(:each) do
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
    end

    it 'should create API-Devices-Update-Alarm url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Devices-Update-Alarm OAuth request' do
      stub_request(:post, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      error_message = helpful_errors(@api_method, 'post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
                      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Activities method' do
    before(:each) do
      @api_method = 'api-get-activities' 
      @api_url = "/1/user/-/activities/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Activities',
        'date'              => @date,
        'Accept-Locale'     => 'en_US',
        'Accept-Language'   => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Activities url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Activities OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Activities method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-activities' 
      @api_url = "/1/user/#{@user_id}/activities/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Activities',
        'date'            => @date,
        'user-id'         => @user_id,
        'Accept-Locale'   => 'en_US',
        'Accept-Language' => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Activities url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Activities OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      @params.delete('user-id')
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Activity method' do
    before(:each) do
      @api_method = 'api-get-activity' 
      @api_url = "/1/activities/#{@activity_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Activity',
        'activity-id'     => @activity_id,
        'Accept-Locale'   => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Activity url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Activity OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Activity-Daily-Goals method' do
    before(:each) do
      @api_method = 'api-get-activity-daily-goals' 
      @api_url = "/1/user/-/activities/goals/daily.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Activity-Daily-Goals',
        'Accept-Language' => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Activity-Daily-Goals url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Activity-Daily-Goals OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Activity-Stats method' do
    before(:each) do
      @api_method = 'api-get-activity-stats' 
      @api_url = "/1/user/-/activities.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Activity-Stats',
        'Accept-Language' => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Activity-Stats url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Activity-Stats OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Activity-Stats method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-activity-stats' 
      @api_url = "/1/user/#{@user_id}/activities.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Activity-Stats',
        'user-id'     => @user_id,
        'Accept-Language' => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Activity-Stats url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Activity-Stats OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end
  end

  context 'API-Get-Activity-Weekly-Goals method' do
    before(:each) do
      @api_method = 'api-get-activity-weekly-goals' 
      @api_url = "/1/user/-/activities/goals/weekly.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Activity-Weekly-Goals',
        'Accept-Language' => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Activity-Weekly-Goals url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Activity-Weekly-Goals OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Badges method' do
    before(:each) do
      @api_method = 'api-get-badges' 
      @api_url = "/1/user/-/badges.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Badges',
        'Accept-Locale'   => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Badges url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Badges OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Badges method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-activities' 
      @api_url = "/1/user/#{@user_id}/badges.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Badges',
        'user-id'         => @user_id,
        'Accept-Locale'   => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Badges url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Badges OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end
  end

  context 'API-Get-Blood-Pressure method' do
    before(:each) do
      @api_method = 'api-get-blood-pressure' 
      @api_url = "/1/user/-/bp/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Blood-Pressure',
        'date'            => @date,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Blood-Pressure url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Blood-Pressure OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Body-Fat method' do
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

    it 'should create API-Get-Body-Fat <date> url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Fat <base-date>/<end-date> url' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@date_range[1]}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['end-date'] = @date_range[1]
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Fat <base-date>/<period> url' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@period}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['period'] = @period
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Fat <date> OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should create API-Get-Body-Fat <base-date>/<end-date> OAuth request' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@date_range[1]}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['end-date'] = @date_range[1]
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should create API-Get-Body-Fat <base-date>/<period> OAuth request' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@period}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['period'] = @period
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Body-Fat-Goal method' do
    before(:each) do
      @api_method = 'api-get-body-fat-goal' 
      @api_url = "/1/user/-/body/log/fat/goal.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Body-Fat-Goal',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Body-Fat-Goal url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Fat-Goal OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Body-Measurements method' do
    before(:each) do
      @api_method = 'api-get-body-measurements' 
      @api_url = "/1/user/-/body/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Body-Measurements',
        'date'            => @date,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Body-Measurements url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Measurements OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Body-Measurements method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-body-measurements' 
      @api_url = "/1/user/#{@user_id}/body/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Body-Measurements',
        'date'            => @date,
        'user-id'         => @user_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Body-Measurements url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Measurements OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      @params.delete('user-id')
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Body-Weight method' do
    before(:each) do
      @params = {}
      @api_method = 'api-get-body-weight'
      @api_url = "/1/user/-/body/log/weight/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Body-Weight',
        'date'            => @date,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Body-Weight <date> url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Weight <base-date>/<end-date> url' do
      @api_url = "/1/user/-/body/log/weight/date/#{@date_range[0]}/#{@date_range[1]}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['end-date'] = @date_range[1]
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Weight <base-date>/<period> url' do
      @api_url = "/1/user/-/body/log/weight/date/#{@date_range[0]}/#{@period}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['period'] = @period
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Weight <date> OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should create API-Get-Body-Weight <base-date>/<end-date> OAuth request' do
      @api_url = "/1/user/-/body/log/weight/date/#{@date_range[0]}/#{@date_range[1]}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['end-date'] = @date_range[1]
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should create API-Get-Body-Weight <base-date>/<period> OAuth request' do
      @api_url = "/1/user/-/body/log/weight/date/#{@date_range[0]}/#{@period}.#{@response_format}"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['period'] = @period
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Body-Weight-Goal method' do
    before(:each) do
      @api_method = 'api-get-body-weight-goal' 
      @api_url = "/1/user/-/body/log/weight/goal.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Body-Weight-Goal',
        'Accept-Language'       => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Body-Weight-Goal url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Weight-Goal OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Device method' do
    before(:each) do
      @params = {}
      @api_method = 'api-get-device' 
      @api_url = "/1/user/-/devices/#{@device_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Device',
        'device-id'       => @device_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Device url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Device OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Device method with _user-id_ instead of auth tokens' do
    before(:each) do
      @params = {}
      @api_method = 'api-get-device' 
      @api_url = "/1/user/#{@user_id}/devices/#{@device_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Device',
        'device-id'       => @device_id,
        'user-id'         => @user_id,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Device url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Device OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      @params.delete('user-id')
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Devices' do
    before(:each) do
      @api_method = 'api-get-devices' 
      @api_url = "/1/user/-/devices.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Devices',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Devices url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Devices OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Favorite-Activities method' do
    before(:each) do
      @api_method = 'api-get-favorite-activities' 
      @api_url = "/1/user/-/activities/favorite.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Favorite-Activities',
        'Accept-Locale'     => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Favorite-Activities url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Favorite-Activities OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Favorite-Activities method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-favorite-activities' 
      @api_url = "/1/user/#{@user_id}/activities/favorite.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Favorite-Activities',
        'user-id'         => @user_id,
        'Accept-Locale'   => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Favorite-Activities url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Favorite-Activities OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      @params.delete('user-id')
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Favorite-Foods method' do
    before(:each) do
      @api_method = 'api-get-favorite-foods'
      @api_url = "/1/user/-/foods/log/favorite.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Favorite-Foods',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Favorite-Foods url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Favorite-Foods OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Food method' do
    before(:each) do
      @api_method = 'api-get-food'
      @api_url = "/1/foods/#{@food_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Food',
        'food-id'         => @food_id,
        'Accept-Locale'   => 'en_US', 
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Food url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Food OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Food-Goals method' do
    before(:each) do
      @api_method = 'api-get-food-goals'
      @api_url = "/1/user/-/foods/log/goal.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Food-Goals',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Food-Goals url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Food-Goals OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Foods method' do
    before(:each) do
      @api_method = 'api-get-foods' 
      @api_url = "/1/user/-/foods/log/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Foods',
        'Accept-Locale'     => 'en_US',
        'date'              => @date,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Foods url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Foods OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Foods method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-foods' 
      @api_url = "/1/user/#{@user_id}/foods/log/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Foods',
        'date'            => @date,
        'user-id'         => @user_id,
        'Accept-Locale'   => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Foods url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Foods OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      @params.delete('user-id')
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Food-Units method' do
    before(:each) do
      @api_method = 'api-get-food-units'
      @api_url = "/1/foods/units.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Food-Units',
        'Accept-Locale'   => 'en_US', 
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Food-Units url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Food-Units OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end
  end

  context 'API-Get-Frequent-Activities method' do
    before(:each) do
      @api_method = 'api-get-frequent-activities' 
      @api_url = "/1/user/-/activities/frequent.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Frequent-Activities',
        'Accept-Language'   => 'en_US',
        'Accept-Locale'     => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Frequent-Activities url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Frequent-Activities OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Frequent-Foods method' do
    before(:each) do
      @api_method = 'api-get-frequent-foods' 
      @api_url = "/1/user/-/foods/log/frequent.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Frequent-Foods',
        'Accept-Locale'     => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Frequent-Foods url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Frequent-Foods OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Friends method' do
    before(:each) do
      @api_method = 'api-get-friends' 
      @api_url = "/1/user/-/friends.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Friends',
        'Accept-Language'       => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Friends url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Friends OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Friends method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-friends' 
      @api_url = "/1/user/#{@user_id}/friends.#{@response_format}"
      @params = {
        'api-method'      => 'API-Get-Friends',
        'user-id'         => @user_id,
        'Accept-Language'       => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Friends url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Friends OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      @params.delete('user-id')
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Friends-Leaderboard method' do
    before(:each) do
      @api_method = 'api-get-friends-leaderboard' 
      @api_url = "/1/user/-/friends/leaderboard.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Friends-Leaderboard',
        'Accept-Language'       => 'en_US',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Friends-Leaderboard url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Friends-Leaderboard OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Glucose method' do
    before(:each) do
      @api_method = 'api-get-glucose' 
      @api_url = "/1/user/-/glucose/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'        => 'API-Get-Glucose',
        'Accept-Language'       => 'en_US',
        'date'              => @date,
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Get-Glucose url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Get-Glucose OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if _user-id_ and auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end






  context 'API-Search-Foods method' do
    before(:each) do
      @api_method = 'api-search-foods'
      @api_url = "/1/foods/search.#{@response_format}?query=banana%20cream%20pie"
      @params = { 
        'api-method'      => 'API-Search-Foods',
        'query'           => 'banana cream pie',
        'response-format'     => @response_format,
      }
    end

    it 'should create API-Search-Foods url' do
      expect(subject.build_url(@params, @params['api-method'].downcase)).to eq(@api_url)
    end

    it 'should create API-Search-Foods OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      error_message = helpful_errors(@api_method, 'required_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end
    
end
