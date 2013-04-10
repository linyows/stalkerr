require 'string-irc'

module Stalkerr::Extensions
  module String
    def constantize
      names = self.split('::')
      names.shift if names.empty? || names.first.empty?
      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name, false) ?
          constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end

    def split_by_crlf
      self.split(/\r\n|\n/).map { |v| v unless v.eql? '' }.compact
    end

    def to_irc_color
      StringIrc.new(self)
    end
  end
end

::String.__send__(:include, Stalkerr::Extensions::String)
