require 'spec_helper'

describe Fitbit::Api do
  subject do
    Fitbit::Api.new({})
  end

  before(:all) do
    @consumer_key = 'user_consumer_key'
    @consumer_secret = 'user_consumer_secret'
    @auth_token = 'user_token'
    @auth_secret = 'user_secret'
    @api_version = 1
  end

  context 'invalid Fitbit API method' do
    before(:each) do
      @params = { 'api-method' => 'API-Search-Fudd' }
    end
    it 'should return a helpful error' do
      error_message = "#{@params['api-method']} is not a valid Fitbit API method."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq("#{error_message}")
    end
  end

  context 'API-Accept-Invite method' do
    before(:each) do
      @params = {
        'api-method' => 'API-Accept-Invite',
        'from-user-id' => 'r2d2c3p0',
        'post_parameters' => { 'accept' => 'true' }
      }
    end

    it 'should create API-Accept-Invite url' do
      api_accept_invite_url = '/1/user/-/friends/invitations/r2d2c3p0.xml'
      expect(subject.build_url(@api_version, @params)).to eq(api_accept_invite_url)
    end

    it 'should create API-Accept-Invite OAuth request' do
      api_accept_invite_url = subject.build_url(@api_version, @params)
      stub_request(:post, "api.fitbit.com#{api_accept_invite_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      @params['post_parameters'] = ""
      post_parameters = ['accept']
      error_message = "api-accept-invite requires POST Parameters #{post_parameters}. You're missing #{post_parameters - @params.keys}."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "api-accept-invite requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end
  end

  context 'API-Add-Favorite-Activity method' do
    before(:each) do
      @params = {
        'api-method'      => 'API-Add-Favorite-Activity',
        'activity-id'     => '8675309'
      }
    end

    it 'should create API-Add-Favorite-Activity url' do
      api_add_favorite_activity_url = '/1/user/-/activities/favorite/8675309.xml'
      expect(subject.build_url(@api_version, @params)).to eq(api_add_favorite_activity_url)
    end

    it 'should create API-Add-Favorite-Activity OAuth request' do
      api_add_favorite_activity_url = subject.build_url(@api_version, @params)
      stub_request(:post, "api.fitbit.com#{api_add_favorite_activity_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "api-add-favorite-activity requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end
  end

  context 'API-Add-Favorite-Food method' do
    before(:each) do
      @params = {
        'api-method'      => 'API-Add-Favorite-Food',
        'food-id'         => '12345'
      }
    end

    it 'should create API-Add-Favorite-Food url' do
      api_add_favorite_food_url = '/1/user/-/foods/log/favorite/12345.xml'
      expect(subject.build_url(@api_version, @params)).to eq(api_add_favorite_food_url)
    end

    it 'should create API-Add-Favorite-Food OAuth request' do
      api_add_favorite_food_url = subject.build_url(@api_version, @params)
      stub_request(:post, "api.fitbit.com#{api_add_favorite_food_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "api-add-favorite-food requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end
  end
  
  context 'API-Browse-Activites method' do
    before(:each) do
      @params = { 
        'api-method' => 'API-Browse-Activites',
        'request-headers'   => { 'Accept-Locale' => 'en_US' }
      }
    end

    it 'should create API-Browse-Activites url' do
      api_browse_activites_url = '/1/activities.xml'
      expect(subject.build_url(@api_version, @params)).to eq(api_browse_activites_url)
    end

    it 'should create API-Browse-Activites OAuth request' do
      api_browse_activites_url = subject.build_url(@api_version, @params)
      stub_request(:get, "api.fitbit.com#{api_browse_activites_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end
  end

  context 'API-Config-Friends-Leaderboard method' do
    before(:each) do
      @params = {
        'api-method'      => 'API-Config-Friends-Leaderboard',
        'post_parameters' => { 'hideMeFromLeaderboard' => 'true' },
        'request_headers' => { 'Accept-Language' => 'en_US' }
      }
      
    end

    it 'should create API-Config-Friends-Leaderboard url' do
      api_config_friends_leaderboard = '/1/user/-/friends/leaderboard.xml'
      expect(subject.build_url(@api_version, @params)).to eq(api_config_friends_leaderboard)
    end

    it 'should create API-Config-Friends-Leaderboard OAuth request' do
      api_config_friends_leaderboard_url = subject.build_url(@api_version, @params)
      headers = @params['request_headers']
      stub_request(:post, "api.fitbit.com#{api_config_friends_leaderboard_url}") do |req|
        headers.each_pair do |k,v|
          req.headers[k] = v
        end
      end 
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      post_parameters = @params['post_parameters'].keys
      @params['post_parameters'] = ""
      error_message = "api-config-friends-leaderboard requires POST Parameters #{post_parameters}. You're missing #{post_parameters - @params.keys}."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "api-config-friends-leaderboard requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end
  end
  
  context 'API-Create-Food method' do
    before(:each) do
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
      api_create_food_url = '/1/foods.xml'
      expect(subject.build_url(@api_version, @params)).to eq(api_create_food_url)
    end

    it 'should create API-Create-Food OAuth request' do
      api_create_food_url = subject.build_url(@api_version, @params)
      stub_request(:post, "api.fitbit.com#{api_create_food_url}") do |req|
        headers.each_pair do |k,v|
          req.headers[k] = v
        end
      end 
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params, @auth_token, @auth_secret)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required POST Parameters are missing' do
      post_parameters = @params['post_parameters'].keys - ['formType', 'description']
      @params['post_parameters'] = ""
      error_message = "api-create-food requires POST Parameters #{post_parameters}. You're missing #{post_parameters - @params.keys}."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end

    it 'should return a helpful error if auth_tokens are missing' do
      error_message = "api-create-food requires user auth_token and auth_secret."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end
  end


  context 'API-Search-Foods method' do
    before(:each) do
      @params = { 
        'api-method'      => 'API-Search-Foods',
        'query'           => 'banana cream pie'
      }
    end

    it 'should create API-Search-Foods url' do
      api_search_foods_url = '/1/foods/search.xml?query=banana%20cream%20pie'
      expect(subject.build_url(@api_version, @params)).to eq(api_search_foods_url)
    end

    it 'should create API-Search-Foods OAuth request' do
      api_search_foods_url = subject.build_url(@api_version, @params)
      stub_request(:get, "api.fitbit.com#{api_search_foods_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

    it 'should return a helpful error if required parameters are missing' do
      @params.delete('query')
      required = ['query']
      error_message = "api-search-foods requires #{required}. You're missing #{required - @params.keys}."
      expect(subject.api_call(@consumer_key, @consumer_secret, @params)).to eq(error_message)
    end
  end
    
end
