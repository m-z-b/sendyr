module Sendyr

	class Error < StandardError
    attr_reader :reason # Symbol for server response

    def initialize(reason)
      super("Sendy :#{reason}")
      @reason = reason
    end

	end
end