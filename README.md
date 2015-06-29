# OmniAuth Fitbit Strategy

[![Build Status](https://travis-ci.org/iamjarvo/omniauth-fitbit.svg?branch=travis-and-old-ruby-syntax)](https://travis-ci.org/iamjarvo/omniauth-fitbit)

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


## Copyright

Copyright (c) 2012 TK Gospodinov. See [LICENSE](https://github.com/tkgospodinov/omniauth-fitbit/blob/master/LICENSE.md) for details.
