ENV['RACK_ENV'] = 'test'

require File.dirname(__FILE__) + '/../lib/sendyr'
require 'webmock/rspec'
require 'pry'

RSpec.configure do |config|
	#config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  # config.raise_errors_for_deprecations!
end
