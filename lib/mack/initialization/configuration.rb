require 'mack-facets'
require 'configatron'
require File.join(File.dirname(__FILE__), 'boot_loader')
require File.join(File.dirname(__FILE__), '..', 'core_extensions', 'kernel')
require File.join(File.dirname(__FILE__), '..', 'utils', 'paths')
boot_load(:configuration) do
  module Mack
  
    # Returns the root of the current Mack application
    def self.root
      ENV["MACK_ROOT"] ||= FileUtils.pwd
    end
  
    # Returns the environment of the current Mack application
    def self.env
      ENV["MACK_ENV"] ||= "development"
    end
  
    # All configuration for the Mack subsystem happens here. Each of the default environments,
    # production, development, and test have their own default configuration options. These
    # get merged with overall default options.
    module Configuration # :nodoc:
      unless const_defined?("LOADED")
        configatron.mack.render_url_timeout = 5
        configatron.mack.cache_classes = true
        configatron.mack.use_lint = true
        configatron.mack.show_exceptions = true
        configatron.mack.use_sessions = true
        configatron.mack.session_id = '_mack_session_id'
        configatron.mack.cookie_values = {:path => '/'}
        configatron.mack.site_domain = 'http://localhost:3000'
        configatron.mack.testing_framework = :rspec
        configatron.mack.rspec_file_pattern = 'test/**/*_spec.rb'
        configatron.mack.test_case_file_pattern = 'test/**/*_test.rb'
        configatron.mack.session_store = :cookie
        configatron.mack.disable_forgery_detector = false
        configatron.mack.assets.max_distribution = 4
        configatron.mack.assets.hosts = ''
        configatron.mack.cookie_session_store.expiry_time = 4.hours
        
        configatron.log.level = :info
        configatron.log.detailed_requests = true
        configatron.log.disable_initialization_logging = false
        configatron.log.root = Mack::Paths.log
        configatron.log.colors.db = :cyan
        configatron.log.colors.error = :red
        configatron.log.colors.fatal = :red
        configatron.log.colors.warn = :yellow
        configatron.log.colors.completed = :purple      
      
        if Mack.env == 'production'
          configatron.mack.use_lint = false
          configatron.mack.show_exceptions = false
          configatron.log.level = :info
          configatron.log.detailed_requests = true
        end
      
        if Mack.env == 'development'
          configatron.mack.cache_classes = false
          configatron.log.level = :debug
        end

        if Mack.env == 'test'
          configatron.mack.cookie_values = {}
          configatron.mack.session_store = :test
          configatron.mack.disable_forgery_detector = true
          configatron.mack.run_remote_tests = true
          configatron.log.level = :error
        end

        if File.exists?(Mack::Paths.configatron('default.rb'))
          require Mack::Paths.configatron('default.rb')
        end
      
        if File.exists?(Mack::Paths.configatron("#{Mack.env}.rb"))
          require Mack::Paths.configatron("#{Mack.env}.rb")
        end
    
        def self.dump
          configatron.to_hash
        end
        
        LOADED = true
        
      end
    
    end
  end
end