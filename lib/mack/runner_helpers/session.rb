require File.join(File.dirname(__FILE__), "base")
module Mack
  module RunnerHelpers # :nodoc:
    class Session < Mack::RunnerHelpers::Base
      
      attr_accessor :sess_id
      
      def start(request, response, cookies)
        if configatron.mack.use_sessions
          self.sess_id = retrieve_session_id(request, response, cookies)
          unless self.sess_id
            self.sess_id = create_new_session(request, response, cookies)
          else
            sess = Mack::SessionStore.get(self.sess_id, request, response, cookies)
            if sess
              request.session = sess
            else
              # we couldn't find it in the store, so we need to create it:
              self.sess_id = create_new_session(request, response, cookies)
            end
          end
        end
      end
      
      def complete(request, response, cookies)
        if configatron.mack.use_sessions
          unless response.redirection?
            request.session.delete(:tell)
          end
          Mack::SessionStore.set(request.session.id, request, response, cookies)
        end
      end
      
      private
      def retrieve_session_id(request, response, cookies)
        cookies[configatron.mack.session_id]
      end
      
      def create_new_session(request, response, cookies)
        id = String.randomize(40).downcase
        cookies[configatron.mack.session_id] = {:value => id, :expires => nil}
        sess = Mack::Session.new(id)
        request.session = sess
        Mack::SessionStore.set(request.session.id, request, response, cookies)
        id
      end
      
    end # Session
  end # RunnerHelpers
end # Mack