require 'optparse'
require 'stalkerr'

module Stalkerr::OptParser
  def self.parse!(argv)
    opts = {
      host: Stalkerr::Const::DEFAULT_HOST,
      port: Stalkerr::Const::DEFAULT_PORT,
      log: nil,
      debug: false,
      daemonize: false,
    }

    OptionParser.new do |parser|
      parser.instance_eval do
        self.banner  = "Usage: #{$0} [opts]"
        separator "Options:"

        on("-p", "--port [PORT=#{opts[:port]}]",
           "use PORT (default: #{Stalkerr::Const::DEFAULT_PORT})") do |port|
          opts[:port] = port
        end

        on("-h", "--host [HOST=#{opts[:host]}]",
           "listen HOST (default: #{Stalkerr::Const::DEFAULT_HOST})") do |host|
          opts[:host] = host
        end

        on("-l", "--log LOG", "log file") do |log|
          opts[:log] = log
        end

        on("-d", "--debug", "enable debug mode") do
          opts[:log] = $stdout
          opts[:debug] = true
        end

        on("-D", "--daemonize", "run daemonized in the background") do
          opts[:daemonize] = true
        end

        parse!(argv)
      end
    end
    opts
  end
end
