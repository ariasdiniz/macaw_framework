# frozen_string_literal: true

require_relative 'common/server_base'
require 'openssl'

##
# Class responsible for providing a default
# webserver with Ruby Threads. This Server is subject
# to the MRI Global Interpreter Lock, thus it will use
# only a single physical Thread.
class ThreadServer
  include ServerBase

  attr_reader :context

  ##
  # Create a new instance of ThreadServer.
  # @param {Macaw} macaw
  # @param {Array} endpoints_to_cache
  # @param {MemoryInvalidationMiddleware} cache
  # @return {Server}
  def initialize(macaw, endpoints_to_cache = nil, cache = nil)
    @port = macaw.port
    @bind = macaw.bind
    @macaw = macaw
    @macaw_log = macaw.macaw_log
    @num_threads = macaw.threads
    @work_queue = Queue.new
    set_features
    @cache = {
      cache: cache,
      endpoints_to_cache: endpoints_to_cache || [],
      cached_methods: macaw.cached_methods
    }
    @workers = []
  end

  ##
  # Start running the webserver.
  def run
    @server = TCPServer.new(@bind, @port)
    @server = OpenSSL::SSL::SSLServer.new(@server, @context) if @context
    @workers_mutex = Mutex.new
    @num_threads.times do
      spawn_worker
    end

    Thread.new do
      loop do
        sleep 10
        maintain_worker_pool
      end
    end

    loop do
      @work_queue << @server.accept unless @is_shutting_down
    rescue OpenSSL::SSL::SSLError => e
      @macaw_log&.error("SSL error: #{e.message}")
    rescue IOError, Errno::EBADF
      break
    end
  end

  ##
  # Method Responsible for closing the TCP server.
  def shutdown
    @is_shutting_down = true
    loop do
      break if @work_queue.empty?

      sleep 0.1
    end

    worker_count = @workers_mutex.synchronize { @workers.size }
    worker_count.times { @work_queue << :shutdown }
    @workers.each(&:join)
    @server&.close
  end

  private

  def spawn_worker
    @workers_mutex.synchronize { create_worker }
  end

  def create_worker
    t = Thread.new do
      loop do
        client = @work_queue.pop
        break if client == :shutdown

        handle_client(client)
      end
    end
    @workers << t
    t
  end

  def maintain_worker_pool
    @workers_mutex.synchronize do
      return if @is_shutting_down

      dead_count = @workers.count { |w| !w.alive? }
      @workers.select!(&:alive?)
      dead_count.times do
        @macaw_log&.error('Worker thread died, respawning...')
        create_worker
      end
    end
  end
end
