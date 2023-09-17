# frozen_string_literal: true

require_relative "macaw_framework/errors/endpoint_not_mapped_error"
require_relative "macaw_framework/middlewares/prometheus_middleware"
require_relative "macaw_framework/data_filters/request_data_filtering"
require_relative "macaw_framework/middlewares/memory_invalidation_middleware"
require_relative "macaw_framework/core/cron_runner"
require_relative "macaw_framework/core/thread_server"
require_relative "macaw_framework/version"
require "prometheus/client"
require "securerandom"
require "logger"
require "socket"
require "json"

module MacawFramework
  ##
  # Class responsible for creating endpoints and
  # starting the web server.
  class Macaw
    ##
    # Array containing the routes defined in the application
    attr_reader :routes, :port, :bind, :threads, :macaw_log, :config, :jobs

    ##
    # @param {Logger} custom_log
    def initialize(custom_log: Logger.new($stdout), server: ThreadServer, dir: nil)
      begin
        @routes = []
        @macaw_log ||= custom_log
        @config = JSON.parse(File.read("application.json"))
        @port = @config["macaw"]["port"] || 8080
        @bind = @config["macaw"]["bind"] || "localhost"
        @threads = @config["macaw"]["threads"] || 200
        unless @config["macaw"]["cache"].nil?
          @cache = MemoryInvalidationMiddleware.new(@config["macaw"]["cache"]["cache_invalidation"].to_i || 3_600)
        end
        @prometheus = Prometheus::Client::Registry.new if @config["macaw"]["prometheus"]
        @prometheus_middleware = PrometheusMiddleware.new if @config["macaw"]["prometheus"]
        @prometheus_middleware.configure_prometheus(@prometheus, @config, self) if @config["macaw"]["prometheus"]
      rescue StandardError => e
        @macaw_log&.warn(e.message)
      end
      create_endpoint_public_files(dir)
      @port ||= 8080
      @bind ||= "localhost"
      @config ||= nil
      @threads ||= 200
      @endpoints_to_cache = []
      @prometheus ||= nil
      @prometheus_middleware ||= nil
      @server = server.new(self, @endpoints_to_cache, @cache, @prometheus, @prometheus_middleware)
    end

    ##
    # Creates a GET endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @example
    #
    # macaw = MacawFramework::Macaw.new
    # macaw.get("/hello") do |context|
    #   return "Hello World!", 200, { "Content-Type" => "text/plain" }
    # end
    def get(path, cache: false, &block)
      map_new_endpoint("get", cache, path, &block)
    end

    ##
    # Creates a POST endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Boolean} cache
    # @param {Proc} block
    # @example
    #
    # macaw = MacawFramework::Macaw.new
    # macaw.post("/hello") do |context|
    #   return "Hello World!", 200, { "Content-Type" => "text/plain" }
    # end
    def post(path, cache: false, &block)
      map_new_endpoint("post", cache, path, &block)
    end

    ##
    # Creates a PUT endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @example
    #
    # macaw = MacawFramework::Macaw.new
    # macaw.put("/hello") do |context|
    #   return "Hello World!", 200, { "Content-Type" => "text/plain" }
    # end
    def put(path, cache: false, &block)
      map_new_endpoint("put", cache, path, &block)
    end

    ##
    # Creates a PATCH endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @example
    #
    # macaw = MacawFramework::Macaw.new
    # macaw.patch("/hello") do |context|
    #   return "Hello World!", 200, { "Content-Type" => "text/plain" }
    # end
    def patch(path, cache: false, &block)
      map_new_endpoint("patch", cache, path, &block)
    end

    ##
    # Creates a DELETE endpoint associated
    # with the respective path.
    # @param {String} path
    # @param {Proc} block
    # @example
    #
    # macaw = MacawFramework::Macaw.new
    # macaw.delete("/hello") do |context|
    #   return "Hello World!", 200, { "Content-Type" => "text/plain" }
    # end
    def delete(path, cache: false, &block)
      map_new_endpoint("delete", cache, path, &block)
    end

    ##
    # Spawn and start a thread running the defined cron job.
    # @param {Integer} interval
    # @param {Integer?} start_delay
    # @param {String} job_name
    # @param {Proc} block
    # @example
    #
    # macaw = MacawFramework::Macaw.new
    # macaw.setup_job(interval: 60, start_delay: 60, job_name: "job 1") do
    #   puts "I'm a cron job that runs every minute"
    # end
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
        puts("---------------------------------")
        puts("Starting server at port #{@port}")
        puts("Number of threads: #{@threads}")
        puts("---------------------------------")
      else
        @macaw_log.info("---------------------------------")
        @macaw_log.info("Starting server at port #{@port}")
        @macaw_log.info("Number of threads: #{@threads}")
        @macaw_log.info("---------------------------------")
      end
      server_loop(@server)
    rescue Interrupt
      if @macaw_log.nil?
        puts("Stopping server")
        @server.close
        puts("Macaw stop flying for some seeds...")
      else
        @macaw_log.info("Stopping server")
        @server.close
        @macaw_log.info("Macaw stop flying for some seeds...")
      end
    end

    ##
    # This method is intended to start the framework
    # without an web server. This can be useful when
    # you just want to keep cron jobs running, without
    # mapping any HTTP endpoints.
    def start_without_server!
      @macaw_log.nil? ? puts("Application starting") : @macaw_log.info("Application starting")
      loop { sleep(3600) }
    rescue Interrupt
      @macaw_log.nil? ? puts("Macaw stop flying for some seeds.") : @macaw_log.info("Macaw stop flying for some seeds.")
    end

    private

    def server_loop(server)
      server.run
    end

    def map_new_endpoint(prefix, cache, path, &block)
      @endpoints_to_cache << "#{prefix}.#{RequestDataFiltering.sanitize_method_name(path)}" if cache
      path_clean = RequestDataFiltering.extract_path(path)
      @macaw_log&.info("Defining #{prefix.upcase} endpoint at /#{path}")
      define_singleton_method("#{prefix}.#{path_clean}", block || lambda {
        |context = { headers: {}, body: "", params: {} }|
      })
      @routes << "#{prefix}.#{path_clean}"
    end

    def get_files_public_folder(dir)
      return [] if dir.nil?

      folder_path = Pathname.new(File.expand_path("public", dir))
      file_paths = folder_path.glob("**/*").select(&:file?)
      file_paths.map { |path| "public/#{path.relative_path_from(folder_path)}" }
    end

    def create_endpoint_public_files(dir)
      get_files_public_folder(dir).each do |file|
        get(file) { |_context| return File.read(file).to_s, 200, {} }
      end
    end
  end
end
