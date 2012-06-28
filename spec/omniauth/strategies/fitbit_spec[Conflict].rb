require 'spec_helper'

describe "OmniAuth::Strategies::Fitbit" do
  subject do
    OmniAuth::Strategies::Fitbit.new(nil, @options || {})
  end

  context 'client options' do
    it 'has correct OAuth endpoint' do
      subject.options.client_options.site.should eq('http://api.fitbit.com')
    end

    it 'has correct request token url' do
      subject.options.client_options.request_token_path.should eq('/oauth/request_token')
    end

    it 'has correct access token url' do
      subject.options.client_options.access_token_path.should eq('/oauth/access_token')
    end

    it 'has correct authorize url' do
      subject.options.client_options.authorize_path.should eq('/oauth/authorize')
    end
  end

  context 'uid' do
    before :each do
      access_token = double('access_token')
      access_token.stub('params') { { 'encoded_user_id' => '123ABC'} }
      subject.stub(:access_token) { access_token }
    end

    it 'returns the correct id from raw_info' do
      subject.uid.should eq('123ABC')
    end
  end
end