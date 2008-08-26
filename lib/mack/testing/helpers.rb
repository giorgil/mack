
require "test/unit"

#--
if Mack.env == "test"
  module Mack
    module RunnerHelpers # :nodoc:
      class Session
        private
        def retrieve_session_id(request, response, cookies)
          $current_session_id
        end
      end # Session
    end # RunnerHelpers
  end # Mack
end
#++

module Mack
  module Testing # :nodoc:
    module Helpers
    
      # Runs the given rake task. Takes an optional hash that mimics command line parameters.
      def rake_task(name, env = {}, tasks = [])
        # set up the Rake application
        rake = Rake::Application.new
        Rake.application = rake
      
        [File.join(File.dirname(__FILE__), "..", "..", "mack_tasks.rb"), tasks].flatten.each do |task|
          load(task)
        end
      
        # save the old ENV so we can revert it
        old_env = ENV.to_hash
        # add in the new ENV stuff
        env.each_pair {|k,v| ENV[k.to_s] = v}
      
        begin
          # run the rake task
          rake[name].invoke
        
          # yield for the tests
          yield if block_given?
        
        rescue Exception => e
          raise e
        ensure
          # empty out the ENV
          ENV.clear
          # revert to the ENV before the test started
          old_env.to_hash.each_pair {|k,v| ENV[k] = v}

          # get rid of the Rake application
          Rake.application = nil
        end
      end
    
      # Temporarily changes the application configuration. Changes are reverted after
      # the yield returns.
      def temp_app_config(options = {})
        app_config.load_hash(options, String.randomize)
        yield
        app_config.revert
      end
    
      def remote_test # :nodoc:
        if (app_config.run_remote_tests)
          yield
        end
      end
    
      # Retrieves an instance variable from the controller from a request.
      def assigns(key)
        $mack_app.instance_variable_get("@app").instance_variable_get("@response").instance_variable_get("@controller").instance_variable_get("@#{key}")
      end

      # Performs a 'get' request for the specified uri.
      def get(uri, options = {})
        build_response(request.get(uri, build_request_options(options)))
      end
    
      # Performs a 'put' request for the specified uri.
      def put(uri, options = {})
        if options[:multipart]
          form_input = build_multipart_data(options)
          build_response(request.put(uri, build_request_options({"CONTENT_TYPE" => "multipart/form-data, boundary=Mack-boundary", "CONTENT_LENGTH" => form_input.size, :input => form_input})))
        else
          build_response(request.put(uri, build_request_options({:input => options.to_params})))
        end
      end
      
      # create a wrapper object for file upload testing.
      def file_for_upload(path)
        return Mack::Testing::FileWrapper.new(path)
      end
          
      # Performs a 'post' request for the specified uri.
      def post(uri, options = {})
        if options[:multipart]
          form_input = build_multipart_data(options)
          build_response(request.post(uri, build_request_options({"CONTENT_TYPE" => "multipart/form-data, boundary=Mack-boundary", "CONTENT_LENGTH" => form_input.size, :input => form_input})))
        else
          build_response(request.post(uri, build_request_options({:input => options.to_params})))
        end
      end
    
      # Performs a 'delete' request for the specified uri.
      def delete(uri, options = {})
        build_response(request.delete(uri, build_request_options(options)))
      end
    
      # Returns a Rack::MockRequest. If there isn't one, a new one is created.
      def request
        @request ||= Rack::MockRequest.new(mack_app)
      end
    
      # Returns the last Rack::MockResponse that got generated by a call.
      def response
        @testing_response
      end
    
      # Returns all the Rack::MockResponse objects that get generated by a call.
      def responses
        @responses
      end
    
      # Returns a Mack::Session from the request.
      def session # :nodoc:
        sess = Mack::SessionStore.store.get($current_session_id, nil, nil, nil)
        if sess.nil?
          id = String.randomize(40).downcase
          set_cookie(app_config.mack.session_id, id)
          sess = Mack::Session.new(id)
          Mack::SessionStore.store.direct_set(id, sess)
          $current_session_id = id
          sess          
        end
        sess
      end
    
      # Used to create a 'session' around a block of code. This is great of 'integration' tests.
      def in_session
        @_mack_in_session = true
        clear_session
        $current_session_id = session.id
        yield
        $current_session_id = nil
        clear_session
        @_mack_in_session = false
      end
    
      # Clears all the sessions.
      def clear_session
        Mack::SessionStore.store.expire_all
      end
    
      # Returns a Hash of cookies from the response.
      def cookies
        test_cookies
      end
    
      # Sets a cookie to be used for the next request
      def set_cookie(name, value)
        test_cookies[name] = value
      end
    
      # Removes a cookie.
      def remove_cookie(name)
        test_cookies.delete(name)
      end
    
      private
      
      def build_multipart_data(options)
        form_input = ""
        boundary = "--Mack-boundary\r\n"
        options.each_pair do |k, v|
          if v.kind_of?(Mack::Testing::FileWrapper)
            form_input += boundary
            form_input += "content-disposition: form-data; name=\"#{k}\"; filename=\"#{v.file_name}\"\r\n"
            form_input += "Content-Type: #{v.mime}\r\n\r\n"
            form_input += "#{v.content}\r\n"
          elsif k != :multipart 
            form_input += boundary
            form_input += "content-disposition: form-data; name=\"#{k}\"\r\n"
            form_input += "Content-Type: text/plain\r\n\r\n"
            form_input += "#{v}\r\n"
          end
        end
        form_input += boundary
        return form_input
      end
      
      
      def test_cookies
        @test_cookies = {} if @test_cookies.nil?
        @test_cookies
      end
    
      def mack_app
        if $mack_app.nil?
          $mack_app = Rack::Recursive.new(Mack::Runner.new)
        end
        $mack_app
      end
    
      def build_request_options(options)
        {"HTTP_COOKIE" => test_cookies.join("%s=%s", "; ")}.merge(options)
      end
    
      def build_response(res)
        @responses = [res]
        strip_cookies_from_response(res)
        # only retry if it's a redirect request
        if res.redirect? 
          until res.successful?
            [res].flatten.each do |r|
              strip_cookies_from_response(r)
            end
            res = request.get(res["Location"])
            @responses << res
          end
        end
        @testing_response = Mack::Testing::Response.new(@responses)
      end
    
      def strip_cookies_from_response(res)
        unless res.original_headers["Set-Cookie"].nil?
          res.original_headers["Set-Cookie"].each do |ck|
            spt = ck.split("=")
            name = spt.first
            value = spt.last
            if name == app_config.mack.session_id
              value = nil unless @_mack_in_session
            end
            set_cookie(name, value)
          end
        end
      end
    
    end # Helpers
  end # Testing
end # Mack

Test::Unit::TestCase.send(:include, Mack::Testing::Helpers)