# OmniAuth Fitbit Strategy [![Build Status](https://travis-ci.org/tkgospodinov/omniauth-fitbit.svg?branch=master)](https://travis-ci.org/tkgospodinov/omniauth-fitbit.svg?branch=master)

This gem is an OmniAuth 1.0+ Strategy for the [Fitbit API](https://wiki.fitbit.com/display/API/OAuth+Authentication+in+the+Fitbit+API).

## Latest
Version 2.0.0 was released to rubygems with support for OAuth 2. The new version requires Ruby 2+.

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

With OAuth 2.0, the additional URI parameter  of 'scope' (a space-delimited list of the permissions you are requesting) is required, and should be included in the strategy as well. The URI paramater of 'prompt' is also allowed. Specify if you need to force the Fitbit authentication or the OAuth 2.0 authorization page to be displayed. When used, the redirect_uri parameter must be specified.


```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :fitbit, 'consumer_key', 'consumer_secret', scope: "activity profile", prompt: "login consent"
end
```

To register your application with Fitbit and obtain a consumer key and secret, go to the [Fitbit application registration](https://dev.fitbit.com/apps/new).

For additional information about OmniAuth, visit [OmniAuth wiki](https://github.com/intridea/omniauth/wiki).

For a short tutorial on how to use OmniAuth in your Rails application, visit [this tutsplus.com tutorial](http://net.tutsplus.com/tutorials/ruby/how-to-use-omniauth-to-authenticate-your-users/).


## Copyright

Copyright (c) 2016 TK Gospodinov. See [LICENSE](https://github.com/tkgospodinov/omniauth-fitbit/blob/master/LICENSE.md) for details.
