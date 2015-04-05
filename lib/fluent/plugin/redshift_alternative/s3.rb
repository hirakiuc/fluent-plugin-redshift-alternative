module Fluent
  class RedshiftALternativeOutput
    class S3 < BaseService
      def initialize(options)
        super
        require 'aws-sdk'

        @s3 = Aws::S3::Client.new(
          aws_key_id:  options[:aws_key_id],
          aws_sec_key: options[:aws_sec_key],
          region:      options[:s3_region]
        )
      end

      # save chunk to s3 bucket
      #
      # @param io [IO]
      # @return s3 path
      def save(io)
        # create a file path with time format
        s3path = create_s3path(@bucket, @path)

        ## upload gz to s3
        #@bucket.objects[s3path].write(Pathname.new(tmp.path),
        #                              acl: :bucket_owner_full_control)

        # TODO: check arguments !
        @s3.put_object(
          bucket: @bucket,
          body:   io,
          key:    'key',
          acl:    :bucket_owner_full_control
        )

        s3path
      rescue => e
        log.error 'save failed: ' + e.message
        log.error e.backtrace.join("\n")
        raise e
      end

      private

      def create_s3path(bucket, path)
        # TODO: implement
        ''
      end
    end
  end
end
