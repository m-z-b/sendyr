require 'spec_helper'

describe Sendyr do
	before do
		@base_url = 'http://localhost'
		Sendyr.configure do |c|
			c.url = @base_url
		end
	end

	describe ".configure" do
		it "configures itself properly" do
			url = 'http://example.org'
			api_key = 'abcd'
			timeout = 99
			open_timeout = 42

			Sendyr.configure do |c|
				c.url = url
				c.api_key = api_key
				c.timeout = timeout
				c.open_timeout = open_timeout
			end

			expect(Sendyr.configuration.url).to eq url
			expect(Sendyr.configuration.api_key).to eq api_key
			expect(Sendyr.configuration.timeout).to eq timeout
			expect(Sendyr.configuration.open_timeout).to eq open_timeout
		end
	end
end
