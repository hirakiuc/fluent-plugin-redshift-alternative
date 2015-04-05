module Fluent
  class RedshiftALternativeOutput
    class Redshift < BaseService
      def initialize(options)
        super

        require 'aws-sdk'
        @db_conf = {}
      end

      def describe_columns
        log.debug 'query table_columns'
        execute(describe_query)
      end

      def copy_s3_file(s3path)
        log.debug 'start copying from s3_uri:' + s3path
        execute(copy_query(s3path))
      end

      private

      def execute(query)
        conn = PG.connect(@db_conf)
        conn.exec(query)
      ensure
        conn.close if conn
      end

      def describe_query
        # TODO
      end

      def copy_query
        # TODO:
      end
    end
  end
end
