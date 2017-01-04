require 'spec_helper'
require 'fitbit_api_helper'

RSpec.configure do |c|
  c.include FitbitApiHelper
end

describe Fitbit::Api do
  subject do
    Fitbit::Api.new({})
  end

  before(:all) do
    @params = {}
    @consumer_key = random_data(:token)
    @consumer_secret = random_data(:token)
    @auth_token = random_data(:token)
    @auth_secret = random_data(:token)
    @date = random_data(:fixed_date)
    @date_range = random_data(:date_range)
    @fitbit_id = random_data(:fitbit_id)
    @period = random_data(:period)
    @resource_path = random_data(:resource_path)
    @time = random_data(:time)
  end

  before(:each) do
    @response_format = random_data(:response_format)
  end

  context 'Invalid Fitbit API method' do
    it 'Raises Error: <api-method> is not a valid Fitbit API method' do
      @params = { 'api-method' => 'API-Search-Fudd' }
      error_message = "#{@params['api-method'].downcase} is not a valid Fitbit API method."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing response-format' do
    it 'Defaults to xml response-format' do
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
      @api_url = "/1/user/-/activities/#{@activity_log_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Activity-Log',
        'activity-log-id' => @fitbit_id, 
        'response-format' => @response_format,
      }
    end

    it 'Raises Error: <api-method> requires <required>. You\'re missing <required-supplied>.' do
      @params.delete('activity-log-id')
      error_message = helpful_errors(@params['api-method'], 'url_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing URL parameters when API method supports multiple dynamic urls based on date or date range' do
    before(:each) do
      @api_method = 'api-get-body-fat'
      @api_url = "/1/user/-/body/log/fat/date/#{@date}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Get-Body-Fat',
        'date'                => @date,
        'response-format'     => @response_format,
      }
    end

    it "Raises Error: <api-method> requires 1 of 3 options: (1) ['date'] (2) ['base-date', 'end-date'] (3) ['base-date', 'period']" do
      @params.delete('date')
      error_message = helpful_errors(@params['api-method'], 'url_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing required auth tokens or user-id' do
    it 'Raises Error: <api-method> requires user auth_token and auth_secret' do
      @api_method = 'api-accept-invite'
      @api_url = "/1/user/-/friends/invitations/#{@fitbit_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Accept-Invite',
        'accept'              => 'true',
        'from-user-id'        => @fitbit_id,
        'response-format'     => @response_format,
      }
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end

    it "Raises Error: <api-method> requires user auth_token and auth_secret, unless you include [\"user-id\"]." do
      @api_method = 'api-get-badges' 
      @api_url = "/1/user/-/badges.#{@response_format}"
      @params = {
        'api-method'          => 'API-Get-Badges',
        'Accept-Locale'       => 'en_US',
        'response-format'     => @response_format,
      }
      error_message = "#{@api_method} requires user auth_token and auth_secret, unless you include [\"user-id\"]."
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing required POST parameters' do
    before(:each) do
      @api_url = "/1/user/-/friends/invitations/#{@fitbit_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Accept-Invite',
        'from-user-id'        => @fitbit_id,
        'response-format'     => @response_format,
      }
    end

    it 'Raises Error: <api-method> requires POST parameters <required>, You\'re missing <required-supplied>.' do
      error_message = helpful_errors(@params['api-method'], 'post_parameters', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing required optional POST parameters (where using one parameter requires using another related parameter)' do
    before(:each) do
      @api_url = "/1/user/-/activities.#{@response_format}"
      @params = {
        'api-method'          => 'API-Log-Activity',
        'activityId'          => @fitbit_id,
        'startTime'           => @time,
        'durationMillis'      => '10000',
        'date'                => @date,
        'response-format'     => @response_format,
      }
    end

    it 'Raises Error: <api-method> requires <missing_parameter> when you use <current_parameter>.' do
      @params.delete('activityId')
      @params['activityName'] = @activity_name
      error_message = helpful_errors(@params['api-method'], 'required_if', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Missing one_required POST parameter (where at least one of these parameters must be used)' do
    before(:each) do
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
      error_message = helpful_errors(@params['api-method'], 'one_required', @params.keys)
      lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
    end
  end

  context 'Exclusive required POST parameters (where one, and only one, of these parameters must be used)' do
    before(:each) do
      @api_url = "/1/user/-/activities.#{@response_format}"
      @params = {
        'api-method'          => 'API-Log-Activity',
        'activityId'          => @fitbit_id,
        'startTime'           => @time,
        'durationMillis'      => '10000',
        'date'                => @date,
        'response-format'     => @response_format,
      }
    end

    context 'When more than one exclusive parameter is included' do
      it 'Raises Error: <api-method> allows only one of these POST parameters: <exclusive>. You used <supplied>.' do
        @params['activityName'] = @fitbit_id
        @params['manualCalories'] = '1000'
        error_message = helpful_errors(@params['api-method'], 'exclusive_too_many', @params.keys)
        lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
      end
    end

    context 'When none of the exclusive parameters are included' do
      it 'Raises Error: <api-method> requires one of these POST parameters: <exclusive>.' do
        @params.delete('activityId')
        error_message = helpful_errors(@params['api-method'], 'exclusive_too_few', @params.keys)
        lambda { subject.api_call(@consumer_key, @consumer_secret, @params) }.should raise_error(RuntimeError, error_message)
      end
    end
  end
  
  context 'Create authenticated GET request' do
    before(:each) do
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
      @api_url = "/1/user/-/devices/tracker/#{@fitbit_id}/alarms.#{@response_format}"
      @params = {
        'api-method'        => 'API-Devices-Get-Alarms',
        'device-id'         => @fitbit_id,
        'response-format'   => @response_format,
      }
      oauth_authenticated :get, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'GET request with user-id authentication instead of auth tokens' do
      @api_url = "/1/user/#{@fitbit_id}/activities.#{@response_format}"
      @params = {
        'api-method'          => 'API-Get-Activity-Stats',
        'Accept-Language'     => 'en_US',
        'response-format'     => @response_format,
        'user-id'             => @fitbit_id,
      }
      oauth_unauthenticated :get, @api_url, @consumer_key, @consumer_secret, @params
    end

    context 'GET request with multiple dynamic urls based on date or time period' do
      before(:each) do
        @api_method = 'api-get-body-fat'
        @api_url = "/1/user/-/body/log/fat/date/#{@date}.#{@response_format}"
        @params = {
          'api-method'          => 'API-Get-Body-Fat',
          'date'                => @date,
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
      @api_url = "/1/user/-/friends/leaderboard.#{@response_format}"
      @params = {
        'api-method'            => 'API-Config-Friends-Leaderboard',
        'hideMeFromLeaderboard' => 'true',
        'Accept-Language'       => 'en_US',
        'response-format'       => @response_format,
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
      @api_url = "/1/user/-/friends/invitations/#{@fitbit_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Accept-Invite',
        'accept'              => 'true',
        'from-user-id'        => @fitbit_id,
        'response-format'     => @response_format,
      }
      ignore = ['api-method', 'response-format', 'from-user-id']
      @api_url = get_url_with_post_parameters(@api_url, @params.dup, ignore)
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'POST request with dynamic url parameters and multiple optional POST parameters' do
      @api_url = "/1/user/-/devices/tracker/#{@fitbit_id}/alarms/#{@fitbit_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Devices-Update-Alarm',
        'device-id'       => @fitbit_id,
        'alarm-id'        => @fitbit_id,
        'time'            => '10:00',
        'enabled'         => 'true',
        'recurring'       => 'true',
        'weekDays'        => '(MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY)',
        'label'           => 'test alarm',
        'snoozeLength'    => '10',
        'snoozeCount'     => '2',
        'vibe'            => 'DEFAULT',
        'Accept-Language' => 'en_US', 
        'response-format' => @response_format,
      }
      ignore = ['api-method', 'response-format', 'Accept-Language', 'device-id', 'alarm-id']
      @api_url = get_url_with_post_parameters(@api_url, @params.dup, ignore)
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end

  context 'Create authenticated DELETE request' do
    it 'DELETE request with dynamic url parameter' do
      @api_url = "/1/user/-/activities/#{@fitbit_id}.#{@response_format}"
      @params = {
        'api-method'      => 'API-Delete-Activity-Log',
        'activity-log-id' => @fitbit_id, 
        'response-format' => @response_format,
      }
      oauth_authenticated :delete, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it 'DELETE request with multiple dynamic url parameters' do
      @api_url = "/1/user/-/devices/tracker/#{@fitbit_id}/alarms/#{@fitbit_id}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Devices-Delete-Alarm',
        'device-id'           => @fitbit_id,
        'alarm-id'            => @fitbit_id,
        'response-format'     => @response_format,
      }
      oauth_authenticated :delete, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end

  context 'API-Get-Time-Series method' do
    before(:each) do
      @api_url = "/1/user/-/#{@resource_path}/date/#{@date_range[0]}/#{@date_range[1]}.#{@response_format}"
      @params = {
        'api-method'          => 'API-Get-Time-Series',
        'response-format'     => @response_format,
        'base-date'           => @date_range[0],
        'end-date'            => @date_range[1],
        'period'              => @period,
        'resource-path'       => @resource_path,
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
      @params['user-id'] = @fitbit_id
      @api_url = "/1/user/#{@fitbit_id}/#{@resource_path}/date/#{@date_range[0]}/#{@period}.#{@response_format}"
      oauth_unauthenticated :get, @api_url, @consumer_key, @consumer_secret, @params
    end
  end

  context 'API-Create-Subscription method' do
    before(:each) do
      @params = {
        'api-method'        => 'API-Create-Subscription',
        'collection-path'   => 'all',
        'subscription-id'   => '550',
        'response-format'   => @response_format,
      }
    end

    it "Create a subscription to all of a user's changes" do
      @api_url = "/1/user/-/apiSubscriptions/550.#{@response_format}"
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it "Create a subscription to user's foods." do
      @params['collection-path'] = 'foods'
      @api_url = "/1/user/-/foods/apiSubscriptions/550-foods.#{@response_format}"
      oauth_authenticated :post, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end

  context 'API-Delete-Subscription method' do
    before(:each) do
      @params = {
        'api-method'        => 'API-Delete-Subscription',
        'collection-path'   => 'all',
        'subscription-id'   => '303',
        'response-format'   => @response_format,
      }
    end

    it "Delete a subscription to all of a user's changes" do
      @api_url = "/1/user/-/apiSubscriptions/303.#{@response_format}"
      oauth_authenticated :delete, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end

    it "Delete a subscription to user's body." do
      @params['collection-path'] = 'body'
      @api_url = "/1/user/-/body/apiSubscriptions/303-body.#{@response_format}"
      oauth_authenticated :delete, @api_url, @consumer_key, @consumer_secret, @params, @auth_token, @auth_secret
    end
  end
end
