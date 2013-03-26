require 'net/irc'
require 'logger'

module Stalkerr::Server
  def self.run
    opts = Stalkerr::OptParser.parse!(ARGV)
    Process.daemon if opts[:daemonize]
    opts[:logger] = Logger.new(opts[:log], 'daily')
    opts[:logger].level = opts[:debug] ? Logger::DEBUG : Logger::INFO
    Net::IRC::Server.new(opts[:host], opts[:port], Stalkerr::Session, opts).start
  end
end
