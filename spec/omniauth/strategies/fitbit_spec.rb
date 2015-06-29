require 'spec_helper'

describe "OmniAuth::Strategies::Fitbit" do
  subject do
    OmniAuth::Strategies::Fitbit.new(nil, @options || {})
  end

  describe 'authorize_params' do
    it 'includes :display' do
      subject.options["authorize_params"].should include(:display)
    end
  end

  context 'client options' do
    it 'has correct OAuth endpoint' do
      subject.options.client_options.site.should eq('https://api.fitbit.com')
    end

    it 'has correct request token url' do
      subject.options.client_options.request_token_path.should eq('/oauth/request_token')
    end

    it 'has correct access token url' do
      subject.options.client_options.access_token_path.should eq('/oauth/access_token')
    end

    it 'has correct authorize url' do
      subject.options.client_options.authorize_url.should eq('https://www.fitbit.com/oauth/authorize')
    end

  end

  context 'uid' do
    before :each do
      access_token = double('access_token')
      access_token.stub('params') { { 'encoded_user_id' => '123ABC' } }
      subject.stub(:access_token) { access_token }
    end

    it 'returns the correct id from raw_info' do
      subject.uid.should eq('123ABC')
    end
  end

  context 'info' do
    before :each do
      subject.stub(:raw_info) {
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
      subject.info[:name].should eq("JD")
    end

    it 'returns the correct full name from raw_info' do
      subject.info[:full_name].should eq("John Doe")
    end

    it 'returns the correct display name from raw_info' do
      subject.info[:display_name].should eq("JD")
    end

    it 'returns the correct nickname from raw_info' do
      subject.info[:nickname].should eq("Johnnie")
    end

    it 'returns the correct gender from raw_info' do
      subject.info[:gender].should eq("MALE")
    end

    it 'returns the correct gender from raw_info' do
      subject.info[:about_me].should eq("I live in Kansas City, MO")
    end

    it 'returns the correct gender from raw_info' do
      subject.info[:city].should eq("Kansas City")
    end

    it 'returns the correct gender from raw_info' do
      subject.info[:state].should eq("MO")
    end

    it 'returns the correct gender from raw_info' do
      subject.info[:country].should eq("US")
    end
  end

  context 'dateOfBirth is empty' do
    before :each do
      subject.stub(:raw_info) {
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
      subject.info[:dob].should be_nil
    end
  end
end
