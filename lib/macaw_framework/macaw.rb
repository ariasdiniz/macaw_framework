# frozen_string_literal: true

require_relative 'errors/endpoint_not_mapped_error'
require_relative 'errors/payload_too_large_error'
require_relative 'data_filters/request_data_filtering'
require_relative 'middlewares/memory_invalidation_middleware'
require_relative 'core/thread_server'
require_relative 'version'
require 'singleton'
require 'pathname'
require 'logger'
require 'socket'
require 'json'

##
# Main module for all Macaw classes
module MacawFramework; end

##
# Class responsible for creating endpoints and
# starting the web server.
class MacawFramework::Macaw
  attr_reader :routes, :macaw_log, :config, :cached_methods, :keep_alive_timeout, :max_body_size
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
    @server = @server_class.new(self, @endpoints_to_cache, @cache)
    Signal.trap('TERM') { raise Interrupt }
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

  private

  def setup_default_configs
    @port ||= 8080
    @bind ||= '0.0.0.0'
    @config ||= nil
    @threads ||= 200
    @endpoints_to_cache = []
  end

  def apply_options(custom_log)
    setup_basic_config(custom_log)
    setup_cache
  rescue StandardError => e
    @macaw_log&.warn(e.message)
  end

  def setup_cache
    return if @config['macaw']['cache'].nil?

    @cache = MemoryInvalidationMiddleware.new(@config.dig('macaw', 'cache', 'cache_invalidation')&.to_i || 3_600)
  end

  def setup_basic_config(custom_log)
    @routes = []
    @cached_methods = {}
    @macaw_log ||= custom_log
    config_file = ENV.fetch('MACAW_CONFIG', 'application.json')
    @config = JSON.parse(File.read(config_file))
    @port = @config['macaw']['port'] || 8080
    @bind = @config['macaw']['bind'] || '0.0.0.0'
    @threads = @config['macaw']['threads'] || 200
    @keep_alive_timeout = @config['macaw']['keep_alive_timeout'] || 30
    @max_body_size = @config.dig('macaw', 'max_body_size')&.to_i || 1_048_576
  rescue Errno::ENOENT
    @macaw_log&.warn("Config file '#{config_file}' not found, using default settings.")
    @config = { 'macaw' => {} }
    @keep_alive_timeout = 30
    @max_body_size = 1_048_576
  rescue JSON::ParserError => e
    @macaw_log&.warn("Config file '#{config_file}' is not valid JSON: #{e.message}. Using default settings.")
    @config = { 'macaw' => {} }
    @keep_alive_timeout = 30
    @max_body_size = 1_048_576
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
