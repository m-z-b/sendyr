require "faraday"
require "require_all"
require_all File.dirname(__FILE__) + "/sendyr"

module Sendyr
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :url, :api_key, :noop
    attr_accessor :timeout # Time to get the response (seconds)
    attr_accessor :open_timeout # Time to open a connection (seconds)

    def initialize
      @timeout = 5
      @open_timeout = 5
    end
  end
end
