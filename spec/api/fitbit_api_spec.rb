require 'spec_helper'

describe Fitbit::Api do
  subject do
    Fitbit::Api.new({})
  end

  def helpful_errors api_method, data_type, supplied_data
    required_data = get_required_data(api_method, data_type)
    missing_data = delete_required_data(required_data, data_type)
    case data_type
    when 'post_parameters'
      "#{api_method} requires POST Parameters #{required_data}. You're missing #{missing_data}."
    when 'exclusive_post_parameters'
      exclusive_data = get_exclusive_data(api_method, 'post_parameters')
      extra_data = get_extra_data(exclusive_data)
      "#{api_method} allows only one of these POST Parameters #{exclusive_data}. You used #{extra_data}."
    when 'required_parameters'
      "#{api_method} requires #{required_data}. You're missing #{missing_data}."
    else
      "#{api_method} is not a valid error type."
    end
  end

  def get_required_data api_method, data_type
    @fitbit_methods[api_method][data_type]
  end

  def get_exclusive_data api_method, data_type
    post_parameters = @fitbit_methods[api_method][data_type]
    exclusive_post_parameters = post_parameters.select { |x| x.is_a? Array } if post_parameters
    exclusive_post_parameters.flatten if exclusive_post_parameters
  end

  def delete_required_data required_data, data_type
    if data_type == 'required_parameters'
      required_data.each { |parameter| @params.delete(parameter) }
    elsif data_type == 'post_parameters'
      required_data.each { |parameter| @params[data_type].delete(parameter) unless parameter.is_a? Array }
    end
  end

  def get_extra_data exclusive_data
    extra_data = exclusive_data.each { |exclusive| @params['post_parameters'][exclusive] = 'cheese' } if exclusive_data
    extra_data.map { |data| "'#{data}'" }.join(' AND ')
  end

  before(:all) do
    @consumer_key = 'user_consumer_key'
    @consumer_secret = 'user_consumer_secret'
    @auth_token = 'user_token'
    @auth_secret = 'user_secret'
    @api_version = 1
    @fitbit_methods = subject.get_fitbit_methods
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
      @api_url = '/1/user/-/friends/invitations/r2d2c3p0.xml'
      @params = {
        'api-method' => 'API-Accept-Invite',
        'from-user-id' => 'r2d2c3p0',
        'post_parameters' => { 'accept' => 'true' }
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
      @api_url = '/1/user/-/activities/favorite/8675309.xml'
      @params = {
        'api-method'      => 'API-Add-Favorite-Activity',
        'activity-id'     => '8675309'
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
      @api_url = '/1/user/-/foods/log/favorite/12345.xml'
      @params = {
        'api-method'      => 'API-Add-Favorite-Food',
        'food-id'         => '12345'
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
        'api-method' => 'API-Browse-Activites',
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
        'api-method'      => 'API-Config-Friends-Leaderboard',
        'post_parameters' => { 'hideMeFromLeaderboard' => 'true' },
        'request_headers' => { 'Accept-Language' => 'en_US' }
      }
      
    end

    it 'should create API-Config-Friends-Leaderboard url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
    end

    it 'should create API-Config-Friends-Leaderboard OAuth request' do
      headers = @params['request_headers']
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
        'api-method'      => 'API-Create-Food',
        'post_parameters' => { 
          'defaultFoodMeasurementUnitId'  => '1',
          'defaultServingSize'            => '1',
          'calories'                      => '1000',
          'formType'                      => 'LIQUID',
          'description'                   => 'Say something here about the new food'
        },
        'request_headers' => { 'Accept-Locale' => 'en_US' }
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
        'api-method'      => 'API-Create-Invite',
        'post_parameters' => { 
          'invitedUserEmail'              => 'email@email.com'
        }
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
      @api_url = '/1/user/-/activities/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Activity-Log',
        'activity-log-id' => '12345'
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
      @api_url = '/1/user/-/bp/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Blood-Pressure-Log',
        'bp-log-id' => '12345'
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
      @api_url = '/1/user/-/body/log/fat/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Body-Fat-Log',
        'body-fat-log-id' => '12345'
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
      @api_url = '/1/user/-/body/log/weight/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Body-Weight-Log',
        'body-weight-log-id' => '12345'
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
      @api_url = '/1/user/-/activities/favorite/8675309.xml'
      @params = {
        'api-method'      => 'API-Delete-Favorite-Activity',
        'activity-id'     => '8675309'
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
      @api_url = '/1/user/-/foods/log/favorite/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Favorite-Food',
        'food-id'         => '12345'
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
      @api_url = '/1/user/-/foods/log/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Food-Log',
        'food-log-id'         => '12345'
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
      @api_url = '/1/user/-/heart/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Heart-Rate-Log',
        'heart-log-id'         => '12345'
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
      @api_url = '/1/user/-/sleep/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Sleep-Log',
        'sleep-log-id'         => '12345'
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
      @api_url = '/1/user/-/foods/log/water/12345.xml'
      @params = {
        'api-method'      => 'API-Delete-Water-Log',
        'water-log-id'         => '12345'
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
      @api_url = '/1/user/-/devices/tracker/8675309/alarms.xml'
      @params = {
        'api-method'      => 'API-Devices-Add-Alarm',
        'device-id'     => '8675309',
        'post_parameters' => { 
          'time'            => '10:00',
          'enabled'         => 'true',
          'recurring'       => 'true',
          'weekDays'        => '(MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY)',
          'label'           => 'test alarm',
          'snoozeLength'    => '10',
          'snoozeCount'     => '2',
          'vibe'            => 'DEFAULT',
        },
        'request_headers' => { 'Accept-Language' => 'en_US' }
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
      @api_url = '/1/user/-/devices/tracker/8675309/alarms/1800555.xml'
      @params = {
        'api-method'      => 'API-Devices-Delete-Alarm',
        'device-id'     => '8675309',
        'alarm-id'     => '1800555',
      }
    end

    it 'should create API-Devices-Delete-Alarm url' do
      expect(subject.build_url(@api_version, @params)).to eq(@api_url)
    end

    it 'should create API-Devices-Delete-Alarm OAuth request' do
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

  context 'API-Devices-Get-Alarms method' do
    before(:each) do
      @api_method = 'api-devices-get-alarms' 
      @api_url = '/1/user/-/devices/tracker/8675309/alarms.xml'
      @params = {
        'api-method'      => 'API-Devices-Get-Alarms',
        'device-id'     => '8675309',
      }
    end

    it 'should create API-Devices-Get-Alarms' do
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
