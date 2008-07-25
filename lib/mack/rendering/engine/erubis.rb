require File.join(File.dirname(__FILE__), "base")
module Mack
  module Rendering # :nodoc:
    module Engine # :nodoc:
      # Allows use of the Builder::XmlMarkup engine to be used with rendering.
      class Erubis < Mack::Rendering::Engine::Base
        
        def render(io, binding)
          src = Mack::Rendering::Engine::Erubis::TemplateCache.instance.cache[io]
          if src.nil?
            src = ::Erubis::Eruby.new(io).src
            Mack::Rendering::Engine::Erubis::TemplateCache.instance.cache[io] = src
          end
          eval(src, binding)
        end
        
        def extension
          :erb
        end
        
        def concat(txt, b)
          eval( "_buf", b) << txt
        end
        
        # See Mack::Rendering::ViewTemplate content_for for more details.
        # Thanks Merb.
        def capture(*args, &block)
          # get the buffer from the block's binding
          buffer = _erb_buffer( block.binding ) rescue nil

          # If there is no buffer, just call the block and get the contents
          if buffer.nil?
            block.call(*args)
          # If there is a buffer, execute the block, then extract its contents
          else
            pos = buffer.length
            block.call(*args)

            # extract the block
            data = buffer[pos..-1]

            # replace it in the original with empty string
            buffer[pos..-1] = ''

            data
          end
        end
        
        private
        def _erb_buffer( the_binding ) # :nodoc:
          eval( "_buf", the_binding, __FILE__, __LINE__)
        end
        
        class TemplateCache # :nodoc:
          include Singleton
          
          attr_reader :cache
          
          def initialize
            @cache = {}
          end
          
        end
        
      end # Erubis
    end # Engines
  end # Rendering
end # Mack