# frozen_string_literal: true
require 'berkeley_library/logging'

module Gingr
  module Logging
    class << self
      def logger
        @logger ||= BerkeleyLibrary::Logging::Loggers.new_readable_logger(STDOUT)
      end
    end

    def logger
      Logging.logger
    end
  end
end
