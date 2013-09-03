require 'spec_helper'

describe Fitbit::Api do
  subject do
    Fitbit::Api.new({})
  end

  def helpful_errors api_method, data_type, supplied_data
    required_data = get_required_data(@api_method, data_type)
    missing_data = delete_required_data(supplied_data, required_data, data_type)
    case data_type
    when 'post_parameters'
      "#{api_method} requires POST Parameters #{required_data}. You're missing #{missing_data}."
    when 'required_parameters'
      "#{api_method} requires #{required_data}. You're missing #{missing_data}."
    else
      "#{api_method} is not a valid error type."
    end
  end

  def get_required_data api_method, data_type
    @fitbit_methods[@api_method][data_type]
  end

  def delete_required_data supplied_data, required_data, data_type
    if data_type == 'required_parameters'
      required_data.each { |parameter| @params.delete(parameter) }
    else
      required_data.each { |parameter| @params[data_type].delete(parameter) }
    end
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
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
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
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
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

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
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
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
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
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
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
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "#{@api_method} requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
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
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end
  end
    
end
