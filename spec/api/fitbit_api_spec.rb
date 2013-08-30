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
        'accept' => 'true'
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

    it 'should return a helpful error if required parameters are missing' do
      @params.delete('accept')
      required = ['accept']
      error_message = "api-accept-invite requires #{required}. You're missing #{required - @params.keys}."
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
      @params = { 'api-method' => 'API-Browse-Activites' }
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
