# OmniAuth Fitbit Strategy [![Build Status](https://semaphoreci.com/api/v1/fsc/omniauth-fitbit/branches/master/badge.svg)](https://semaphoreci.com/fsc/omniauth-fitbit)

**As per the creators:**
- This gem is an OmniAuth 1.0+ Strategy for the [Fitbit API]    (https://wiki.fitbit.com/display/API/OAuth+Authentication+in+the+Fitbit+API).
- Version 2.0.0 was released to rubygems with support for OAuth 2. The new version requires Ruby 2+.

**This was forked and updated because:**
- There seemed to be little activity or response from the original.
- The original needed maintenance and updates for some feature functionality.
- The original could do with some general code and documentation upgrades.

## Usage

Add the strategy to your `Gemfile`:

```ruby
gem 'omniauth-fitbit', github: 'Steven-Chang/omniauth-fitbit'  
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

With OAuth 2.0, the additional URI parameter  of 'scope' (a space-delimited list of the permissions you are requesting) is required, and should be included in the strategy as well.


```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :fitbit, 'consumer_key', 'consumer_secret', scope: "activity profile"
end
```

To register your application with Fitbit and obtain a consumer key and secret, go to the [Fitbit application registration](https://dev.fitbit.com/apps/new).

For additional information about OmniAuth, visit [OmniAuth wiki](https://github.com/intridea/omniauth/wiki).

For a short tutorial on how to use OmniAuth in your Rails application, visit [this tutsplus.com tutorial](http://net.tutsplus.com/tutorials/ruby/how-to-use-omniauth-to-authenticate-your-users/).


## Copyright

Copyright (c) 2016 TK Gospodinov. See [LICENSE](https://github.com/tkgospodinov/omniauth-fitbit/blob/master/LICENSE.md) for details.
