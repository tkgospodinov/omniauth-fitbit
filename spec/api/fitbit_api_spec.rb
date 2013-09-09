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
    @api_version = 1
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

  context 'invalid Fitbit API method' do
    before(:each) do
      @params = { 'api-method' => 'API-Search-Fudd' }
    end
    it 'should return a helpful error' do
      error_message = "#{@params['api-method'].downcase} is not a valid Fitbit API method."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Accept-Invite method' do
    before(:each) do
      @api_method = 'api-accept-invite'
      @api_url = "/1/user/-/friends/invitations/#{@user_id}.xml"
      @params = {
        'api-method' => 'API-Accept-Invite',
        'from-user-id' => @user_id,
        'accept' => 'true' 
      }
    end

    it 'should create API-Accept-Invite url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/activities/favorite/#{@activity_id}.xml"
      @params = {
        'api-method'      => 'API-Add-Favorite-Activity',
        'activity-id'     => @activity_id,
      }
    end

    it 'should create API-Add-Favorite-Activity url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/foods/log/favorite/#{@food_id}.xml"
      @params = {
        'api-method'      => 'API-Add-Favorite-Food',
        'food-id'         => @food_id,
      }
    end

    it 'should create API-Add-Favorite-Food url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/activities.xml'
      @params = { 
        'api-method'        => 'API-Browse-Activites',
        'request-headers'   => { 'Accept-Locale' => 'en_US' }
      }
    end

    it 'should create API-Browse-Activites url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/user/-/friends/leaderboard.xml'
      @params = {
        'api-method'            => 'API-Config-Friends-Leaderboard',
        'hideMeFromLeaderboard' => 'true',
        'Accept-Language'       => 'en_US',
      }
      
    end

    it 'should create API-Config-Friends-Leaderboard url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/foods.xml'
      @params = {
        'api-method'                    => 'API-Create-Food',
        'name'                          => 'food name',
        'defaultFoodMeasurementUnitId'  => '1',
        'defaultServingSize'            => '1',
        'calories'                      => '1000',
        'formType'                      => 'LIQUID',
        'description'                   => 'Say something here about the new food',
        'Accept-Locale'                 => 'en_US', 
      }
    end

    it 'should create API-Create-Food url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/user/-/friends/invitations.xml'
      @params = {
        'api-method'          => 'API-Create-Invite',
        'invitedUserEmail'    => 'email@email.com',
      }
    end

    it 'should create API-Create-Invite url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/activities/#{@activity_log_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Activity-Log',
        'activity-log-id' => @activity_log_id, 
      }
    end

    it 'should create API-Delete-Activity-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/bp/#{@bp_log_id}.xml"
      @params = {
        'api-method'    => 'API-Delete-Blood-Pressure-Log',
        'bp-log-id'     => @bp_log_id,
      }
    end

    it 'should create API-Delete-Blood-Pressure-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/body/log/fat/#{@body_fat_log_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Body-Fat-Log',
        'body-fat-log-id' => @body_fat_log_id,
      }
    end

    it 'should create API-Delete-Body-Fat-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/body/log/weight/#{@body_weight_log_id}.xml"
      @params = {
        'api-method'          => 'API-Delete-Body-Weight-Log',
        'body-weight-log-id'  => @body_weight_log_id,
      }
    end

    it 'should create API-Delete-Body-Weight-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/activities/favorite/#{@activity_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Favorite-Activity',
        'activity-id'     => @activity_id,
      }
    end

    it 'should create API-Delete-Favorite-Activity url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/foods/log/favorite/#{@food_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Favorite-Food',
        'food-id'         => @food_id,
      }
    end

    it 'should create API-Delete-Favorite-Food url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/foods/log/#{@food_log_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Food-Log',
        'food-log-id'     => @food_log_id,
      }
    end

    it 'should create API-Delete-Food-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/heart/#{@heart_log_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Heart-Rate-Log',
        'heart-log-id'    => @heart_log_id,
      }
    end

    it 'should create API-Delete-Heart-Rate-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/sleep/#{@sleep_log_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Sleep-Log',
        'sleep-log-id'    => @sleep_log_id,
      }
    end

    it 'should create API-Delete-Sleep-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/foods/log/water/#{@water_log_id}.xml"
      @params = {
        'api-method'      => 'API-Delete-Water-Log',
        'water-log-id'    => @water_log_id,
      }
    end

    it 'should create API-Delete-Water-Log url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms.xml"
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
      }
    end

    it 'should create API-Devices-Add-Alarm url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms/#{@alarm_id}.xml"
      @params = {
        'api-method'    => 'API-Devices-Delete-Alarm',
        'device-id'     => @device_id,
        'alarm-id'      => @alarm_id,
      }
    end

    it 'should create API-Devices-Delete-Alarm url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms.xml"
      @params = {
        'api-method'    => 'API-Devices-Get-Alarms',
        'device-id'     => @device_id,
      }
    end

    it 'should create API-Devices-Get-Alarms url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/devices/tracker/#{@device_id}/alarms/#{@alarm_id}.xml"
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
      }
    end

    it 'should create API-Devices-Update-Alarm url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/activities/date/#{@date}.xml"
      @params = {
        'api-method'        => 'API-Get-Activities',
        'date'              => @date,
        'Accept-Locale'     => 'en_US',
        'Accept-Language'   => 'en_US',
      }
    end

    it 'should create API-Get-Activities url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'API-Get-Activities method with _user-id_ instead of auth tokens' do
    before(:each) do
      @api_method = 'api-get-activities' 
      @api_url = "/1/user/#{@user_id}/activities/date/#{@date}.xml"
      @params = {
        'api-method'      => 'API-Get-Activities',
        'date'            => @date,
        'user-id'         => @user_id,
        'Accept-Locale'   => 'en_US',
        'Accept-Language' => 'en_US',
      }
    end

    it 'should create API-Get-Activities url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
  end

  context 'API-Get-Activity method' do
    before(:each) do
      @api_method = 'api-get-activity' 
      @api_url = "/1/activities/#{@activity_id}.xml"
      @params = {
        'api-method'      => 'API-Get-Activity',
        'activity-id'     => @activity_id,
        'Accept-Locale'   => 'en_US',
      }
    end

    it 'should create API-Get-Activity url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/user/-/activities/goals/daily.xml'
      @params = {
        'api-method'      => 'API-Get-Activity-Daily-Goals',
        'Accept-Language' => 'en_US',
      }
    end

    it 'should create API-Get-Activity-Daily-Goals url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/user/-/activities.xml'
      @params = {
        'api-method'      => 'API-Get-Activity-Stats',
        'Accept-Language' => 'en_US',
      }
    end

    it 'should create API-Get-Activity-Stats url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/#{@user_id}/activities.xml"
      @params = {
        'api-method'      => 'API-Get-Activity-Stats',
        'user-id'     => @user_id,
        'Accept-Language' => 'en_US',
      }
    end

    it 'should create API-Get-Activity-Stats url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/user/-/activities/goals/weekly.xml'
      @params = {
        'api-method'      => 'API-Get-Activity-Weekly-Goals',
        'Accept-Language' => 'en_US',
      }
    end

    it 'should create API-Get-Activity-Weekly-Goals url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = '/1/user/-/badges.xml'
      @params = {
        'api-method'      => 'API-Get-Badges',
        'Accept-Locale'   => 'en_US',
      }
    end

    it 'should create API-Get-Badges url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/#{@user_id}/badges.xml"
      @params = {
        'api-method'      => 'API-Get-Badges',
        'user-id'         => @user_id,
        'Accept-Locale'   => 'en_US',
      }
    end

    it 'should create API-Get-Badges url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_url = "/1/user/-/bp/date/#{@date}.xml"
      @params = {
        'api-method'      => 'API-Get-Blood-Pressure',
        'date'            => @date,
      }
    end

    it 'should create API-Get-Blood-Pressure url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
      @api_method = 'api-get-body-fat'
      @api_url = "/1/user/-/body/log/fat/date/#{@date}.xml"
      @params = {
        'api-method'      => 'API-Get-Body-Fat',
        'date'            => @date,
      }
    end

    it 'should create API-Get-Body-Fat <date> url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Fat <base-date>/<end-date> url' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@date_range[1]}.xml"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['end-date'] = @date_range[1]
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Fat <base-date>/<period> url' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@period}.xml"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['period'] = @period
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
    end

    it 'should create API-Get-Body-Fat <date> OAuth request' do
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should create API-Get-Body-Fat <base-date>/<end-date> OAuth request' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@date_range[1]}.xml"
      @params.delete('date')
      @params['base-date'] = @date_range[0]
      @params['end-date'] = @date_range[1]
      stub_request(:get, "api.fitbit.com#{@api_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should create API-Get-Body-Fat <base-date>/<period> OAuth request' do
      @api_url = "/1/user/-/body/log/fat/date/#{@date_range[0]}/#{@period}.xml"
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

  context 'API-Search-Foods method' do
    before(:each) do
      @api_method = 'api-search-foods'
      @api_url = '/1/foods/search.xml?query=banana%20cream%20pie'
      @params = { 
        'api-method'      => 'API-Search-Foods',
        'query'           => 'banana cream pie'
      }
    end

    it 'should create API-Search-Foods url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
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
