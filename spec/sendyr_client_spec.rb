require 'spec_helper'

describe Sendyr::Client do
	before do
		@base_url = 'http://localhost'
		@api_key  = '1234567890'
		@email    = 'john@example.org'
		@list_id  = '1'
		@timeout  = 42
		@open_timeout = 1

		Sendyr.configure do |c|
			c.url     = @base_url
			c.api_key = @api_key
			c.timeout = @timeout
			c.open_timeout = @open_timeout
		end
	end

	let(:client) { Sendyr::Client.new(@list_id) }

	describe ".initialize" do
	  it "should properly set instance variable defaults" do
	  	client = Sendyr::Client.new(@list_id)
	  	expect(client.list_id).to eq @list_id
	  	expect(client.base_uri).to eq @base_url
	  	expect(client.api_key).to eq @api_key
	  	expect(client.timeout).to eq @timeout
	  	expect(client.open_timeout).to eq @open_timeout
	  end
	  it "should properly set instance variable defaults" do
	  	client = Sendyr::Client.new(@list_id, timeout: 27, open_timeout: 23)
	  	expect(client.list_id).to eq @list_id
	  	expect(client.base_uri).to eq @base_url
	  	expect(client.api_key).to eq @api_key
	  	expect(client.timeout).to eq 27
	  	expect(client.open_timeout).to eq 23
	  end
	end

	describe "#subscribe" do
		it "raises exception if email is missing" do
			expect {
				client.subscribe(foo: @email)
			}.to raise_error(ArgumentError, 'You must specify :email.')
		end

		it "subscribes the email and passes the other arguments" do
			stub_request(:post, "#{@base_url}/subscribe").
			  with(:body => {"FirstName"=>"John",
			  							 "boolean"=>"true",
			  							 "email"=> @email,
			  							 "list"=>@list_id,
			  							 "name"=>"John Smith"}).
        to_return(:status => 200, :body => "true")

			expect(client.subscribe(email: @email, name: 'John Smith', "FirstName" => "John")).to eq :ok
		end

		it "succeeds when the response body is '1'" do
			# The API doc says it should return 'true', but we see '1' in real life.
			stub_request(:post, "#{@base_url}/subscribe").
			  with(:body => {"boolean"=>"true",
			  							 "email"=> @email,
			  							 "name" => "John Smith",
			  							 "list"=>@list_id}).
        to_return(:status => 200, :body => "1")

			expect(client.subscribe(email: @email, name: 'John Smith')).to eq :ok
		end

		it "fails when the response message is an error" do
			stub_request(:post, "#{@base_url}/subscribe").
			  with(:body => {"FirstName"=>"John",
			  							 "boolean"=>"true",
			  							 "email"=> @email,
			  							 "list"=>@list_id,
			  							 "name"=>"John Smith"}).
        to_return(:status => 200, :body => "Some fields are missing.")

			expect{ client.subscribe(email: @email, name: 'John Smith', "FirstName" => "John")}.to raise_error( Sendyr::Error, "Sendy :missing_fields" )
		end
	end

	describe "#unsubscribe" do
		it "raises exception if email is missing" do
			expect {
				client.unsubscribe(foo: @email)
			}.to raise_error(ArgumentError, 'You must specify :email.')
		end

		it "unsubscribes the email" do
			stub_request(:post, "#{@base_url}/unsubscribe").
			  with(:body => {"boolean"=>"true",
			  							 "email"=> @email,
			  							 "list"=>@list_id}).
        to_return(:status => 200, :body => "true")

			expect(client.unsubscribe(email: @email)).to eq :ok
		end

		it "succeeds when the response body is '1'" do
			# The API doc says it should return 'true', but we see '1' in real life.
			stub_request(:post, "#{@base_url}/unsubscribe").
			  with(:body => {	"boolean"=>"true",
			 							 		"email"=> @email,
			  							 	"list"=>@list_id}).
        to_return(:status => 200, :body => "1")

			expect(client.unsubscribe(email: @email)).to eq :ok
		end

		it "fails when the response message is an error" do
			stub_request(:post, "#{@base_url}/unsubscribe").
				with(:body => {"boolean"=>"true",
											 "email"=> @email,
											 "list"=>@list_id}).
        to_return(:status => 200, :body => "Invalid email address.")

			expect{ client.unsubscribe(email: @email) }.to raise_error( Sendyr::Error, "Sendy :invalid_email_address" )
		end
	end

	describe "#subscription_status" do
		it "raises exception if email is missing" do
			expect {
				client.subscription_status(foo: @email)
			}.to raise_error(ArgumentError, 'You must specify :email.')
		end

		it "returns the correct response when email is not in list" do
			body = "Email does not exist in list"

			stub_request(:post, "#{@base_url}/api/subscribers/subscription-status.php").
				with(:body => {"api_key"=> @api_key,
											 "email"  => @email,
											 "list_id"=> @list_id}).
        to_return(:status => 200, :body => body)

      expect(client.subscription_status(email: @email)).to eq :not_in_list
		end

		it "returns the correct response when other messages are returned" do
			messages = ["Subscribed","Unsubscribed","Unconfirmed","Bounced","Soft Bounced","Complained"]
			expected_responses = [:subscribed, :unsubscribed, :unconfirmed, :bounced, :soft_bounced, :complained]

			messages.each_index do |i|
				stub_request(:post, "#{@base_url}/api/subscribers/subscription-status.php").
					with(:body => {"api_key"=> @api_key,
												 "email"  => @email,
												 "list_id"=> @list_id}).
	        to_return(:status => 200, :body => messages[i])

	      expect(client.subscription_status(email: @email)).to eq expected_responses[i]
			end
		end
	end

	describe "#active_subscriber_count" do
		it "returns the number of subscribers when the body is an integer" do
			stub_request(:post, "#{@base_url}/api/subscribers/active-subscriber-count.php").
				with(:body => {"api_key"=> @api_key,
											 "list_id"=> @list_id}).
        to_return(:status => 200, :body => "10")

      expect(client.active_subscriber_count).to eq 10
		end

		it "to raise an error when the body is an error message" do
			stub_request(:post, "#{@base_url}/api/subscribers/active-subscriber-count.php").
				with(:body => {"api_key"=> @api_key,
											 "list_id"=> @list_id}).
        to_return(:status => 200, :body => "Invalid list ID.")

      expect{ client.active_subscriber_count }.to raise_error( Sendyr::Error, "Sendy :invalid_list_id" )
		end
	end

		describe "#update_subscription" do
			it "changes the user name if the user was subscribed" do
				new_name = "Jennifer Smith"
				stub_request(:post, "#{@base_url}/api/subscribers/subscription-status.php").
					with(:body => {"api_key"=> @api_key,
												 "email"  => @email,
												 "list_id"=> @list_id}).
	        to_return(:status => 200, :body => "Subscribed")
				stub_request(:post, "#{@base_url}/subscribe").
				  with(:body => {"boolean"=>"true",
				  							 "email"=> @email,
				  							 "name" => new_name,
				  							 "list"=>@list_id}).
	        to_return(:status => 200, :body => "1")

				expect(client.subscribe(email: @email, name: new_name)).to eq :ok
			end

			it "raises Error :not_in_list if email was never subscribed" do
				stub_request(:post, "#{@base_url}/api/subscribers/subscription-status.php").
					with(:body => {"api_key"=> @api_key,
												 "email"  => @email,
												 "list_id"=> @list_id}).
	        to_return(:status => 200, :body => "Email does not exist in list")

	      expect{ client.update_subscription(@email, { name: 'John'}) }.to raise_error( Sendyr::Error, "Sendy :not_in_list" )
			end

			it "unsubscribes then creates a new subscription if trying to change email address" do
				new_email = 'newemail@example.org'
				name      = 'John Smith'

				stub_request(:post, "#{@base_url}/api/subscribers/subscription-status.php").
					with(:body => {"api_key"=> @api_key,
												 "email"  => @email,
												 "list_id"=> @list_id}).
	        to_return(:status => 200, :body => "Subscribed")
				stub_request(:post, "#{@base_url}/unsubscribe").
				  with(:body => {	"boolean"=>"true",
				 							 		"email"=> @email,
				  							 	"list"=>@list_id}).
	        to_return(:status => 200, :body => "1")
				stub_request(:post, "#{@base_url}/subscribe").
				  with(:body => {"boolean"=>"true",
				  							 "email"=> new_email,
				  							 "name" => name,
				  							 "list"=>@list_id}).
	        to_return(:status => 200, :body => "1")

				expect(client.update_subscription(@email, { email: 'newemail@example.org', name: name})).to eq :ok
			end

			it "doesn't change the email if the user complained" do
				new_email = 'newemail@example.org'
				name      = 'John Smith'

				stub_request(:post, "#{@base_url}/api/subscribers/subscription-status.php").
					with(:body => {"api_key"=> @api_key,
												 "email"  => @email,
												 "list_id"=> @list_id}).
	        to_return(:status => 200, :body => "Complained")
  
				expect{ client.update_subscription(@email, { email: 'newemail@example.org', name: name})}.to raise_error( Sendyr::Error, "Sendy :complained") 
			end

			it "doesn't change the email if the user unsubscribed" do
				new_email = 'newemail@example.org'
				name      = 'John Smith'

				stub_request(:post, "#{@base_url}/api/subscribers/subscription-status.php").
					with(:body => {"api_key"=> @api_key,
												 "email"  => @email,
												 "list_id"=> @list_id}).
	        to_return(:status => 200, :body => "Unsubscribed")

				expect{ client.update_subscription(@email, { email: 'newemail@example.org', name: name})}.to raise_error( Sendyr::Error, "Sendy :unsubscribed") 
			end

		end
end
