# OmniAuth Fitbit Strategy

This gem is an OmniAuth 1.0+ Strategy for the [Fitbit API](https://wiki.fitbit.com/display/API/OAuth+Authentication+in+the+Fitbit+API).

## Usage

Add the strategy to your `Gemfile`:

```ruby
gem 'omniauth-fitbit'
```

Then integrate the strategy into your middleware:

```ruby
use OmniAuth::Builder do
  provider :fitbit, 'consumer_key', 'consumer_secret'
end
```

In Rails, create a new file under config/initializers called omniauth.rb to plug the strategy into your middleware stack.

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :fitbit, 'consumer_key', 'consumer_secret'
end
```

To register your application with Fitbit and obtain a consumer key and secret, go to the [Fitbit application registration](https://dev.fitbit.com/apps/new).

For additional information about OmniAuth, visit [OmniAuth wiki](https://github.com/intridea/omniauth/wiki).

For a short tutorial on how to use OmniAuth in your Rails application, visit [this tutsplus.com tutorial](http://net.tutsplus.com/tutorials/ruby/how-to-use-omniauth-to-authenticate-your-users/).

## Accessing the FitBit API

An API call can be instantiated with `Fitbit::Api.new({}).api_call()`  
Each call requires:
* Fitbit consumer_key and consumer_secret
* A params Hash containing the Fitbit api method, plus all required api parameters (see the FitBit Api docs for details)
* Optionally, for authenticated API calls, your user's Fitbit auth token and auth secret

An example of an authenticated API call: 

```ruby
Fitbit::Api.new({}).api_call(
  'consumer_key',
  'consumer_secret',
  params,
  'auth_token',
  'auth_secret'
)
```

The OmniAuth Fitbit API wrapper supports the Fitbit Resource Access API and the Fitbit Subscriptions API.

To access the Resource Access API, consult the API docs and provide the required parameters. For example,
the API-Search-Foods method requires 'api-version', 'query' and 'response-format'. There's also an optional
Request Header parameter, 'Accept-Locale'. A call to API-Search-Foods might look like this:

```ruby
def fibit_foods_search
  params = {
    'api-method'      => 'api-search-foods',
    'query'           => 'pumpkin beer',
    'response-format' => 'json',
    'Accept-Locale'   => 'en_US',
  }
  request = Fitbit::Api.new({}).api_call(
    'consumer_key',
    'consumer_secret',
    params,
    'auth_token',
    'auth_secret'
  )
  @response = request.body
end
```

A couple notes: 'api-version' defaults to '1' and can be omitted from OmniAuth Fitbit API calls.
If you omit the 'response-format', the response will be in the default xml format.

To access the Subscription API, two new api methods were created just for this gem:
API-Create-Subscription and API-Delete-Subscription. The syntax is the same as above. Read the
API docs and supply the required parameters 'collection-path' and 'subscription-id'. 
NOTE: To subscribe to ALL of a user's changes make 'collection-path' = 'all'.

## Copyright

Copyright (c) 2012 TK Gospodinov. See [LICENSE](https://github.com/tkgospodinov/omniauth-fitbit/blob/master/LICENSE.md) for details.
