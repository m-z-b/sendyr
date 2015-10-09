# Sendyr

A Ruby interface for the e-mail newsletter application Sendy.

## Installation

Add this line to your application's Gemfile:

    gem 'sendyr', :git => 'https://github.com/m-z-b/sendyr.git'

And then execute:

    $ bundle

Or [NOT YET - Not published yet] install it yourself as: 

    $ gem install sendyr 

## Usage

		Sendyr.configure do |c|
			c.url     = 'http://my.sendy-install.com'
			c.api_key = '1234567890'
			# c.noop  = true  # You can use this to noop in dev and test environments
            c.timeout = 5 # Read timeout in seconds
            c.open_timeout = 5 # Connection timeout in seconds
		end

		list_id = 'jakgjakjkgjkGJK'
		client = Sendyr::Client.new(list_id)
		client.subscribe(email: 'joe@example.org', name: 'Joe Smith', 'FirstName' => 'Joe')  # => :ok

		client.subscription_status(email: 'joe@example.org') #  => :subscribed

		client.active_subscriber_count  # => 1

		client.unsubscribe(email: 'joe@example.org')  # => :ok

		client.update_subscription('joe@example.org', email: 'newemail@example.com', name: 'Joe Smith', FirstName => 'Joe')  # => :ok

Network or http errors raise a `Faraday::Error` derived exception (see Faraday gem). Sendy server errors raise a `Sendyr::Error` exception, with a `Error#reason` method returning a symbolic error message. 

## History

This was originally based on the sendyr gem by Carl Mercier, but has now been substantially changed to meet different design goals:

1. Timeouts can now be specified for the network calls.
2. Unexpected results now raise exceptions. The `Sendyr::Error` class is raised for server errors, while the required Faraday gem will raise errors for network issues and 400/500 http status codes.
3. Where possible, API calls return a status synmbol (e.g. :ok) indicating a status, rather than true or false
4. The `Sendyr::Error` exception class contains a `Error#reason` which is the last response from the Sendy server (as a symbol). This can be used to distinguish Sendy errors.
5. The status symbols are a canonical form of the Sendy server response, with some changes for brevity, consistency, and Sendy documentation errors. See the `Sendyr::Client#get_status` private method for details.
6. When `noop` is specified in the configuration, the response is now the same as if the api was called successfully.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
