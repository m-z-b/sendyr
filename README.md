# Sendyr

A Ruby interface for the wonderful e-mail newsletter application Sendy.

## Installation

Add this line to your application's Gemfile:

    gem 'sendyr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sendyr

## Usage

		Sendyr.configure do |c|
			c.url     = 'http://my.sendy-install.com'
			c.api_key = '1234567890'
			# c.noop  = true  # You can use this to noop in dev and test environments
		end

		list_id = 1
		client = Sendyr::Client.new(list_id)
		client.subscribe(email: 'joe@example.org', name: 'Joe Smith', 'FirstName' => 'Joe')  # => true

		client.subscription_status(email: 'joe@example.org') #  => :subscribed

		client.active_subscriber_count  # => 1

		client.unsubscribe(email: 'joe@example.org')  # => true

		client.update_subscription('joe@example.org', email: 'newemail@example.com', name: 'Joe Smith', FirstName => 'Joe')  # => true


## History
This was originally based on the sendyr gem by Carl Mercier, but has now changed somewhat in design:
1. Timeouts can now be specified for the network calls.
2. Unexpected results now raise exceptions. The `Sendyr::Error` class is raised for server errors,
   while the underlyhing Faraday gem will raise errors for network issues and 400/500 http status codes.
3. Where possible, API calls return a status synmbol (e.g. :ok) indicating a status, rather than true or false
4. The `Sendyr::Error` exception class contains a `Error#reason` which is the last response from the Sendy server 
   (as a symbol). This can be used to distinguish Sendy errors.
5. The status symbols are a canonical form of the Sendy server response, with some changes for brevity, consistency,
   and Sendy documentation errors.
6. When `noop` is specified in the configuration, the response is now the same as if the api was called successfully.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
