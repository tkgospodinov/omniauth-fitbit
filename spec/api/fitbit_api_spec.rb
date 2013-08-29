require 'spec_helper'

describe Fitbit::Api do
  subject do
    Fitbit::Api.new({})
  end

  before(:all) do
    @consumer_key = 'user_consumer_key'
    @consumer_secret = 'user_consumer_secret'
    @api_version = 1
  end

  context 'API-Search-Foods method' do
    before(:each) do
      @params = { 
        'api-method'      => 'API-Search-Foods',
        'response-format' => 'xml',
        'query'           => 'banana cream pie'
      }
    end

    it 'should create API-Search-Foods url' do
      expect(subject.build_url(@api_version, @params)).to eq('/1/foods/search.xml?query=banana%20cream%20pie')
    end

    it 'should create API-Search-Foods OAuth request' do
      api_search_foods_url = subject.build_url(@api_version, @params)
      stub_request(:get, "api.fitbit.com#{api_search_foods_url}")
      api_call = subject.api_call(@consumer_key, @consumer_secret, @params)
      expect(api_call.class).to eq(Net::HTTPOK)
    end

  end
    
end
