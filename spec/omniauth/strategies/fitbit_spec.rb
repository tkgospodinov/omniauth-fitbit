require 'spec_helper'

describe "OmniAuth::Strategies::Fitbit" do
  subject do
    OmniAuth::Strategies::Fitbit.new(nil, @options || {})
  end

  describe 'response_type' do
    it 'includes :code' do
      expect(subject.options["response_type"]).to include('code')
    end
  end

  describe 'authorize_options' do
    it 'includes :scope' do
      expect(subject.options["authorize_options"]).to include(:scope)
    end

    it 'includes :response_type' do
      expect(subject.options["authorize_options"]).to include(:response_type)
    end

    it 'includes :redirect_uri' do
      expect(subject.options["authorize_options"]).to include(:redirect_uri)
    end
  end

  context 'client options' do
    it 'has correct OAuth endpoint' do
      expect(subject.options.client_options.site).to eq('https://api.fitbit.com')
    end

    it 'has correct authorize url' do
      expect(subject.options.client_options.authorize_url).to eq('https://www.fitbit.com/oauth2/authorize')
    end

    it 'has correct token url' do
      expect(subject.options.client_options.token_url).to eq('https://api.fitbit.com/oauth2/token')
    end
  end

  context 'auth header' do
    before :each do
      subject.options.client_id = 'testclientid'
      subject.options.client_secret = 'testclientsecret'
    end

    it 'returns the correct authorization header value' do
      expect(subject.basic_auth_header).to eq('Basic ' + Base64.strict_encode64("testclientid:testclientsecret"))
    end
  end

  context 'uid' do
    before :each do
      access_token = double('access_token')
      allow(access_token).to receive('params') { { 'user_id' => '123ABC' } }
      allow(subject).to receive(:access_token) { access_token }
    end

    it 'returns the correct id from raw_info' do
      expect(subject.uid).to eq('123ABC')
    end
  end

  context 'info' do
    before :each do
      allow(subject).to receive(:raw_info) {
        {
          "user" =>
          {
            "fullName"    => "John Doe",
            "displayName" => "JD",
            "nickname"    => "Johnnie",
            "gender"      => "MALE",
            "aboutMe"     => "I live in Kansas City, MO",
            "city"        => "Kansas City",
            "state"       => "MO",
            "country"     => "US",
            "dateOfBirth" => "1980-01-01",
            "memberSince" => "2010-01-01",
            "locale"      => "en_US",
            "timezone"    => "America/Chicago"
          }
        }
      }
    end

    it 'returns the correct name from raw_info' do
      expect(subject.info[:name]).to eq("JD")
    end

    it 'returns the correct full name from raw_info' do
      expect(subject.info[:full_name]).to eq("John Doe")
    end

    it 'returns the correct display name from raw_info' do
      expect(subject.info[:display_name]).to eq("JD")
    end

    it 'returns the correct nickname from raw_info' do
      expect(subject.info[:nickname]).to eq("Johnnie")
    end

    it 'returns the correct gender from raw_info' do
      expect(subject.info[:gender]).to eq("MALE")
    end

    it 'returns the correct gender from raw_info' do
      expect(subject.info[:about_me]).to eq("I live in Kansas City, MO")
    end

    it 'returns the correct gender from raw_info' do
      expect(subject.info[:city]).to eq("Kansas City")
    end

    it 'returns the correct gender from raw_info' do
      expect(subject.info[:state]).to eq("MO")
    end

    it 'returns the correct gender from raw_info' do
      expect(subject.info[:country]).to eq("US")
    end
  end

  context 'dateOfBirth is empty' do
    before :each do
      allow(subject).to receive(:raw_info) {
        {
          "user" =>
          {
            "dateOfBirth" => "",
            "memberSince" => "2010-01-01",
          }
        }
      }
    end
    it 'when return nil' do
      expect(subject.info[:dob]).to be_nil
    end
  end
end
