module Sendyr
	class Client
		attr_reader :last_result	# clean_bodyd text of last response from sendy
		attr_reader :api_key
		attr_reader :base_uri
		attr_reader  :list_id
		attr_reader :timeout
		attr_reader :open_timeout

		def initialize(list_id = nil, options = {} )
			@list_id     = list_id
			@api_key     = Sendyr.configuration.api_key
			@base_uri    = Sendyr.configuration.url
			@noop        = Sendyr.configuration.noop || false
			@timeout = options[:timeout] || Sendyr.configuration.timeout
			@open_timeout = options[:open_timeout] || Sendyr.configuration.open_timeout
		end



		# Return :ok or :already_subscribed if successful
		# Raise Sendyr::Error if not, with reason = canonicalized server status
		def subscribe(opts = {})
			return :ok if @noop

			opts = {boolean: true, list: @list_id}.merge(opts)
			raise_if_missing_arg([:email, :list], opts)

			path   = '/subscribe'
			result = post_to(path, opts)

			@last_status = get_status(result)
			raise_unless_status( :ok, :already_subscribed )
		end




		# Although unsubscribing someone who isn't subscribed is an error, it's harmless so
		# we treat it as success
		def unsubscribe(opts = {})
			return :ok if @noop

			opts = {boolean: true, list: @list_id}.merge(opts)
			raise_if_missing_arg([:email, :list], opts)

			path   = '/unsubscribe'
			result = post_to(path, opts)

			@last_status = get_status(result)
			raise_unless_status( :ok, :not_in_list )
		end

		def subscription_status(opts = {})
			return :subscribed if @noop

			opts = {api_key: @api_key, list_id: @list_id}.merge(opts)
			raise_if_missing_arg([:api_key, :email, :list_id, :api_key], opts)

			path   = '/api/subscribers/subscription-status.php'
			result = post_to(path, opts)

			success = [ :subscribed, 
									:unsubscribed, 
									:unconfirmed, 
									:bounced, 
									:soft_bounced, 
									:complained,
								  :not_in_list ]

      @last_status = get_status(result)
      raise_unless_status( *success )
		end

		def update_subscription(email, opts = {})
			return :ok if @noop

			subscription_status(email: email)
			raise_if_status( :not_in_list, :complained, :unsubscribed )

			# If changing email address, unsubscribe then resubscribe
			if (!opts[:email].nil? && opts[:email] != email) &&	[:subscribed, :unconfirmed, :bounced, :soft_bounced].include?(@last_status)
				unsubscribe(email: email)
		 	end

			subscribe({email: email}.merge(opts))
			raise_unless_status( :ok )
		end


		def active_subscriber_count(opts = {})
			return 42 if @noop

			opts = {api_key: @api_key, list_id: @list_id}.merge(opts)
			raise_if_missing_arg([:list_id, :api_key], opts)

			path   = '/api/subscribers/active-subscriber-count.php'
			result = post_to(path, opts)

			cleaned_body = result.body.strip

			if cleaned_body =~ /^[-+]?[0-9]+$/
				cleaned_body.to_i
			else
				raise Error.new( get_status(result) )
			end
		end

	private
		def raise_if_missing_arg(mandatory_fields, opts)
			mandatory_fields.each do |key|
				if opts[key].nil? || opts[key].to_s.strip == ''
					raise ArgumentError.new("You must specify :#{key}.")
				end
			end; nil
		end

		def post_to(path, params)
			conn = Faraday.new do |f|
				f.use Faraday::Request::UrlEncoded
				f.use Faraday::Response::RaiseError	# raise Faraday::ResourceNotFound etc. on server errors
				f.use Faraday::Adapter::NetHttp
			end
			conn.post(url_for(path), params) do |request|
				request.options.timeout = @timeout # How long to read from connection
				request.options.open_timeout = @open_timeout	# How long to set up connection
			end
		end

		def url_for(path)
			return File.join(@base_uri, path)
		end

		# Lower case, no leading/trailing whitespace or '.'
		def get_status(result)
				# No leading/trailing spaces
				# No punctuation or line endings
				# Convert spaces to underscores
				# Convert to symbol
				if result.body.length > 42
					return :configuration_error # Sendy returns a page of HTML if not set up correctly!
				end
				status = result.body.tr('^A-Za-z0-9 ', '').strip.downcase
				case (status) 
					when "1", "true"
													return :ok 
					when ""
													return :empty_response
					when "email does not exist in list" # Too wordy
													return :not_in_list
					when "some fields are missing"			# Too wordy
													return :missing_fields
					else 
													return status.tr(' ', '_').to_sym
				end 
		end

		def raise_unless_status( *list )
			unless list.include?(@last_status)
				raise Error.new( @last_status )
			end
			@last_status
		end

		def raise_if_status( *list )
			if list.include?(@last_status)
				raise Error.new( @last_status )
			end
			@last_status
		end

	end
end

