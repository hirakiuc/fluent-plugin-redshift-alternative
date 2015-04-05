module Fluent
  class RedshiftALternativeOutput
    class BaseService
      attr_reader :log
      def initialize(options)
        @options = options
      end
    end
  end
end
