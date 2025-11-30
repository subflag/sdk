# frozen_string_literal: true

module Subflag
  module Rails
    # Per-request cache for flag evaluations
    #
    # Caches flag values for the duration of a single request to avoid
    # multiple API calls for the same flag.
    #
    # @example Enable in application.rb
    #   # config/application.rb
    #   config.middleware.use Subflag::Rails::RequestCache::Middleware
    #
    # @example Or in initializer
    #   # config/initializers/subflag.rb
    #   Rails.application.config.middleware.use Subflag::Rails::RequestCache::Middleware
    #
    module RequestCache
      class << self
        # Get a cached value or yield to fetch it
        #
        # @param cache_key [String] Unique key for this evaluation
        # @yield Block to execute if not cached
        # @return [Object] Cached or freshly fetched value
        def fetch(cache_key, &block)
          return yield unless enabled?

          cache = current_cache
          return cache[cache_key] if cache.key?(cache_key)

          cache[cache_key] = yield
        end

        # Check if request caching is active
        def enabled?
          Thread.current[:subflag_request_cache].is_a?(Hash)
        end

        # Start a new cache scope
        def start
          Thread.current[:subflag_request_cache] = {}
        end

        # End the cache scope
        def clear
          Thread.current[:subflag_request_cache] = nil
        end

        # Get current cache
        def current_cache
          Thread.current[:subflag_request_cache] ||= {}
        end

        # Get cache stats for debugging
        def stats
          cache = current_cache
          { size: cache.size, keys: cache.keys }
        end
      end

      # Rack middleware for per-request caching
      #
      # Wraps each request in a cache scope so flag evaluations
      # are cached for the duration of the request.
      #
      class Middleware
        def initialize(app)
          @app = app
        end

        def call(env)
          RequestCache.start
          @app.call(env)
        ensure
          RequestCache.clear
        end
      end
    end
  end
end
