module Fluent
  class RedshiftAlternativeOutput < BufferedOutput
    Fluent::Plugin.register_output('redshift_alternative', self)

    config_param :record_log_tag, :string, default: 'log'
    # s3
    config_param :aws_key_id, :string
    config_param :aws_sec_key, :string
    config_param :s3_bucket, :string
    config_param :s3_endpoint, :string, default: nil
    config_param :path, :string, default: ''
    config_param :timestamp_key_format, :string, default: 'year=%Y/month=%m/day=%d/hour=%H/%Y%m%d-%H%M'
    config_param :utc, :bool, default: false
    # redshift
    config_param :redshift_host, :string
    config_param :redshift_port, :integer, default: 5439
    config_param :redshift_dbname, :string
    config_param :redshift_user, :string
    config_param :redshift_password, :string
    config_param :redshift_tablename, :string
    config_param :redshift_schemaname, :string, default: nil
    config_param :redshift_copy_base_options, :string, default: 'FILLRECORD ACCEPTANYDATE TRUNCATECOLUMNS'
    config_param :redshift_copy_options, :string, default: nil
    config_param :redshift_connect_timeout, :integer, default: 10
    # file format
    config_param :file_type, :string, default: nil  # json, tsv, csv, msgpack
    config_param :delimiter, :string, default: nil
    # for debug
    config_param :log_suffix, :string, default: ''

    # Define 'log' method for v0.10.42 or earlier
    define_method('log') { $log } unless method_defined?(:log)

    def initialize
      super

      require_relative 'redshift_alternative/base_service'
      require_relative 'redshift_alternative/s3'
      require_relative 'redshift_alternative/redshift'
    end

    def configure(conf)
      super
      @path = "#{@path}/" unless @path.end_with?('/') # append last slash
      @path = @path[1..-1] if @path.start_with?('/')  # remove head slash
      @utc = true if conf['utc']
      @db_conf = {
        host:            @redshift_host,
        port:            @redshift_port,
        dbname:          @redshift_dbname,
        user:            @redshift_user,
        password:        @redshift_password,
        connect_timeout: @redshift_connect_timeout
      }
      @delimiter = determine_delimiter(@file_type) if @delimiter.nil? or @delimiter.empty?
      log.debug format_log("redshift file_type:#{@file_type} delimiter:'#{@delimiter}'")
      @copy_sql_template = "copy #{table_name_with_schema} from '%s' CREDENTIALS 'aws_access_key_id=#{@aws_key_id};aws_secret_access_key=%s' delimiter '#{@delimiter}' GZIP ESCAPE #{@redshift_copy_base_options} #{@redshift_copy_options};"
    end

    # This method is called when starting.
    # Open sockets or files here.
    def start
      super
      # init s3 conf
      options = {
        access_key_id:     @aws_key_id,
        secret_access_key: @aws_sec_key
      }
      options[:s3_endpoint] = @s3_endpoint if @s3_endpoint
      @s3 = AWS::S3.new(options)
      @bucket = @s3.buckets[@s3_bucket]
    end

    # This method is called when shutting down.
    # Shutdown the thread and close sockets or files here.
    def shutdown
      super
    end

    # This method is called when an event reaches to Fluentd.
    # Convert the event to a raw string.
    def format(tag, time, record)
      if json?
        record.to_msgpack
      elsif msgpack?
        { @record_log_tag => record }.to_msgpack
      else
        "#{record[@record_log_tag]}\n"
      end
    end

    # This method is called every flush interval.
    # Write the buffer chunk to files or databases here.
    # 'chunk' is a buffer chunk that includes multiple formatted events.
    # You can use 'data = chunk.read' to get all events and
    # 'chunk.open {|io| ... }' to get IO objects.
    #
    # NOTE: This method is called by internal thread, not Fluentd's main thread.
    #       So IO wait doesn't affect other plugins.
    #
    # You can use 'chunk.key' to get sliced time.
    # THe format of 'chunk.key' can be configured by the 'time_format' option.
    # The default format is %Y%m%d.
    def write(chunk)
      log.debug format_log('start creating gz.')

      s3path = \
        Tempfile.new('s3-') do |io|
          unless create_gz_file(io, chunk, @delimiter)
            log.debug 'received no valid data.'
            return false # debug
          end

          @s3.save(io)
        end

      begin
        @redshift.copy_s3_file(s3path)
      rescue PG::Error => e
        log.error format_log("failed to copy data into redshift. s3_uri=#{s3_uri}"), error: e.to_s
        raise e unless e.to_s =~ IGNORE_REDSHIFT_ERROR_REGEXP
        return false # for debug
      end
      true # for debug
    end

    # Create gzipped data file.
    #
    # @param io [IO]
    # @param chunk
    # @param delimiter [String][optional]
    # @return true or false
    def create_gz_file(io, chunk, delimiter = nil)
      if json? || msgpack?
        create_gz_file_from_structured_data(io, chunk, delimiter)
      else
        create_gz_file_from_flat_data(io, chunk)
      end
    end

    def create_gz_file_from_flat_data(io, chunk)
      Zlib::GzipWriter.new(io) do |writer|
        chunk.write_to(writer)
      end
    end

    def create_gz_file_from_structured_data(io, chunk, delimiter)
      columns = @redshift.describe_columns
      raise 'failed to fetch the redshift table definition.' if columns.nil?
      if columns.empty?
        log.warn "no table on redshift. table_name=#{table_name_with_schema}"
        return nil
      end

      Zlib::GzipWriter.new(io) do |writer|
        chunk.msgpack_each do |record|
          begin
            hash = json? ? json_to_hash(record[@record_log_tag]) : record[@record_log_tag]
            record_hash = hash.select { |key, _value| columns.include?(key) }

            if record_hash.empty?
              log.warn "no data match for table columns on redshift. data=#{hash} table_columns=#{columns}"
              next
            end

            writer.write(record_hash.to_json)
          rescue => e
            type = (json?) ? 'json' : 'msgpack'

            log.error "failed to create table text from #{type}. text=(#{record[@record_log_tag]}) error:#{e.message}"
            log.error_backtrace
          end
        end
      end
    end
  end
end
