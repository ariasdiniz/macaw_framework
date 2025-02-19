# frozen_string_literal: true

require_relative 'macaw_framework/errors/endpoint_not_mapped_error'
require_relative 'macaw_framework/middlewares/prometheus_middleware'
require_relative 'macaw_framework/data_filters/request_data_filtering'
require_relative 'macaw_framework/middlewares/memory_invalidation_middleware'
require_relative 'macaw_framework/core/cron_runner'
require_relative 'macaw_framework/core/thread_server'
require_relative 'macaw_framework/version'
require 'prometheus/client'
require 'securerandom'
require 'singleton'
require 'pathname'
require 'logger'
require 'socket'
require 'json'

module MacawFramework
  ##
  # Class responsible for creating endpoints and
  # starting the web server.
  class Macaw
    attr_reader :routes, :macaw_log, :config, :jobs, :cached_methods, :secure_header, :session
    attr_accessor :port, :bind, :threads

    ##
    # Initialize Macaw Class
    # @param {Logger} custom_log
    # @param {ThreadServer} server
    # @param {String?} dir
    def initialize(custom_log: Logger.new($stdout), server: ThreadServer, dir: nil)
      apply_options(custom_log)
      create_endpoint_public_files(dir)
      setup_default_configs
      @server_class = server
    end

    ##
    # Creates a GET endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    #
    # @example
    #   macaw = MacawFramework::Macaw.new
    #   macaw.get("/hello") do |context|
    #     return "Hello World!", 200, { "Content-Type" => "text/plain" }
    #   end
    ##
    def get(path, cache: [], &block)
      map_new_endpoint('get', cache, path, &block)
    end

    ##
    # Creates a POST endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Boolean} cache
    # @param {Proc} block
    # @example
    #
    #   macaw = MacawFramework::Macaw.new
    #   macaw.post("/hello") do |context|
    #     return "Hello World!", 200, { "Content-Type" => "text/plain" }
    #   end
    ##
    def post(path, cache: [], &block)
      map_new_endpoint('post', cache, path, &block)
    end

    ##
    # Creates a PUT endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @example
    #
    #   macaw = MacawFramework::Macaw.new
    #   macaw.put("/hello") do |context|
    #     return "Hello World!", 200, { "Content-Type" => "text/plain" }
    #   end
    ##
    def put(path, cache: [], &block)
      map_new_endpoint('put', cache, path, &block)
    end

    ##
    # Creates a PATCH endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @example
    #
    #   macaw = MacawFramework::Macaw.new
    #   macaw.patch("/hello") do |context|
    #     return "Hello World!", 200, { "Content-Type" => "text/plain" }
    #   end
    ##
    def patch(path, cache: [], &block)
      map_new_endpoint('patch', cache, path, &block)
    end

    ##
    # Creates a DELETE endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @example
    #
    #   macaw = MacawFramework::Macaw.new
    #   macaw.delete("/hello") do |context|
    #     return "Hello World!", 200, { "Content-Type" => "text/plain" }
    #   end
    ##
    def delete(path, cache: [], &block)
      map_new_endpoint('delete', cache, path, &block)
    end

    ##
    # Spawn and start a thread running the defined periodic job.
    # @param {Integer} interval
    # @param {Integer?} start_delay
    # @param {String} job_name
    # @param {Proc} block
    # @example
    #
    #   macaw = MacawFramework::Macaw.new
    #   macaw.setup_job(interval: 60, start_delay: 60, job_name: "job 1") do
    #     puts "I'm a periodic job that runs every minute"
    #   end
    ##
    def setup_job(interval: 60, start_delay: 0, job_name: "job_#{SecureRandom.uuid}", &block)
      @cron_runner ||= CronRunner.new(self)
      @jobs ||= []
      @cron_runner.start_cron_job_thread(interval, start_delay, job_name, &block)
      @jobs << job_name
    end

    ##
    # Starts the web server
    def start!
      if @macaw_log.nil?
        puts('---------------------------------')
        puts("Starting server at port #{@port}")
        puts("Number of threads: #{@threads}")
        puts('---------------------------------')
      else
        @macaw_log.info('---------------------------------')
        @macaw_log.info("Starting server at port #{@port}")
        @macaw_log.info("Number of threads: #{@threads}")
        @macaw_log.info('---------------------------------')
      end
      @server = @server_class.new(self, @endpoints_to_cache, @cache, @prometheus, @prometheus_middleware)
      server_loop(@server)
    rescue Interrupt
      if @macaw_log.nil?
        puts('Stopping server')
        @server.shutdown
        puts('Macaw stop flying for some seeds...')
      else
        @macaw_log.info('Stopping server')
        @server.shutdown
        @macaw_log.info('Macaw stop flying for some seeds...')
      end
    end

    ##
    # This method is intended to start the framework
    # without an web server. This can be useful when
    # you just want to keep cron jobs running, without
    # mapping any HTTP endpoints.
    def start_without_server!
      @macaw_log.nil? ? puts('Application starting') : @macaw_log.info('Application starting')
      loop { sleep(3600) }
    rescue Interrupt
      @macaw_log.nil? ? puts('Macaw stop flying for some seeds.') : @macaw_log.info('Macaw stop flying for some seeds.')
    end

    private

    def setup_default_configs
      @port ||= 8080
      @bind ||= 'localhost'
      @config ||= nil
      @threads ||= 200
      @endpoints_to_cache = []
      @prometheus ||= nil
      @prometheus_middleware ||= nil
    end

    def apply_options(custom_log)
      setup_basic_config(custom_log)
      setup_session
      setup_cache
      setup_prometheus
    rescue StandardError => e
      @macaw_log&.warn(e.message)
    end

    def setup_cache
      return if @config['macaw']['cache'].nil?

      @cache = MemoryInvalidationMiddleware.new(@config['macaw']['cache']['cache_invalidation'].to_i || 3_600)
    end

    def setup_session
      @session = false
      return if @config['macaw']['session'].nil?

      @session = true
      @secure_header = @config['macaw']['session']['secure_header'] || 'X-Session-ID'
    end

    def setup_basic_config(custom_log)
      @routes = []
      @cached_methods = {}
      @macaw_log ||= custom_log
      @config = JSON.parse(File.read('application.json'))
      @port = @config['macaw']['port'] || 8080
      @bind = @config['macaw']['bind'] || 'localhost'
      @threads = @config['macaw']['threads'] || 200
    end

    def setup_prometheus
      return unless @config['macaw']['prometheus']

      @prometheus = Prometheus::Client::Registry.new
      @prometheus_middleware = PrometheusMiddleware.new
      @prometheus_middleware&.configure_prometheus(@prometheus, @config, self)
    end

    def server_loop(server)
      server.run
    end

    def map_new_endpoint(prefix, cache, path, &block)
      @endpoints_to_cache << "#{prefix}.#{RequestDataFiltering.sanitize_method_name(path)}" unless cache.empty?
      @cached_methods["#{prefix}.#{RequestDataFiltering.sanitize_method_name(path)}"] = cache unless cache.empty?
      path_clean = RequestDataFiltering.extract_path(path)
      slash = path[0] == '/' ? '' : '/'
      @macaw_log&.info("Defining #{prefix.upcase} endpoint at #{slash}#{path}")
      define_singleton_method("#{prefix}.#{path_clean}", block || lambda {
        |context = { headers: {}, body: '', params: {} }|
      })
      @routes << "#{prefix}.#{path_clean}"
    end

    def get_files_public_folder(dir)
      return [] if dir.nil?

      folder_path = Pathname.new(File.expand_path('public', dir))
      file_paths = folder_path.glob('**/*').select(&:file?)
      file_paths.map { |path| "public/#{path.relative_path_from(folder_path)}" }
    end

    def create_endpoint_public_files(dir)
      get_files_public_folder(dir).each do |file|
        get(file) { |_context| return File.read(file).to_s, 200, {} }
      end
    end
  end

  ##
  # This singleton class allows to manually cache
  # parameters and other data.
  class Cache
    include Singleton

    attr_accessor :invalidation_frequency

    ##
    # Write a value to Cache memory.
    # Can be called statically or from an instance.
    # @param {String} tag
    # @param {Object} value
    # @param {Integer} expires_in Defaults to 3600.
    # @return nil
    #
    # @example
    #   MacawFramework::Cache.write("name", "Maria", expires_in: 7200)
    def self.write(tag, value, expires_in: 3600)
      MacawFramework::Cache.instance.write(tag, value, expires_in: expires_in)
    end

    ##
    # Write a value to Cache memory.
    # Can be called statically or from an instance.
    # @param {String} tag
    # @param {Object} value
    # @param {Integer} expires_in Defaults to 3600.
    # @return nil
    #
    # @example
    #   MacawFramework::Cache.write("name", "Maria", expires_in: 7200)
    def write(tag, value, expires_in: 3600)
      if read(tag).nil?
        @mutex.synchronize do
          @cache.store(tag, { value: value, expires_in: Time.now + expires_in })
        end
      else
        @cache[tag][:value] = value
        @cache[tag][:expires_in] = Time.now + expires_in
      end
    end

    ##
    # Read the value with the specified tag.
    # Can be called statically or from an instance.
    # @param {String} tag
    # @return {String|nil}
    #
    # @example
    #   MacawFramework::Cache.read("name") # Maria
    def self.read(tag) = MacawFramework::Cache.instance.read(tag)

    ##
    # Read the value with the specified tag.
    # Can be called statically or from an instance.
    # @param {String} tag
    # @return {String|nil}
    #
    # @example
    #   MacawFramework::Cache.read("name") # Maria
    def read(tag) = @cache.dig(tag, :value)

    private

    def initialize
      @cache = {}
      @mutex = Mutex.new
      @invalidation_frequency = 60
      invalidate_cache
    end

    def invalidate_cache
      @invalidator = Thread.new(&method(:invalidation_process))
    end

    def invalidation_process
      loop do
        sleep @invalidation_frequency
        @mutex.synchronize do
          @cache.delete_if { |_, v| v[:expires_in] < Time.now }
        end
      end
    end
  end
end
