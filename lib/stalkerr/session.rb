require 'ostruct'
require 'time'
require 'net/irc'
require 'stalkerr'
Dir["#{File.dirname(__FILE__)}/target/*.rb"].each { |p| require p }

class Stalkerr::Session < Net::IRC::Server::Session

  def initialize(*args)
    super
    @debug = args.last.debug
    @channels = {}
    Dir["#{File.dirname(__FILE__)}/target/*.rb"].each do |path|
      name = File.basename(path, '.rb')
      @channels.merge!(name.to_sym => "##{name}")
    end
  end

  def on_disconnected
    @retrieve_thread.kill rescue nil
  end

  def on_user(m)
    super
    @real, *@opts = @real.split(/\s+/)
    @opts = OpenStruct.new @opts.inject({}) { |r, i|
      key, value = i.split("=", 2)
      r.update key => case value
                      when nil                      then true
                      when /\A\d+\z/                then value.to_i
                      when /\A(?:\d+\.\d*|\.\d+)\z/ then value.to_f
                      else                               value
                      end
    }
  end

  def on_join(m)
    super

    matched = m.params[1].match(/(.*?):(.*)/)
    channel = m.params[0]

    if !@channels.value?(channel) || !matched
      @log.error "#{channel} not found."
    end

    @class_name = "Stalkerr::Target::#{@channels.invert[channel].capitalize}"
    @username = matched[1]
    @password = matched[2]
    post @username, JOIN, channel

    @retrieve_thread = Thread.start do
      loop do
        begin
          target.stalking do |prefix, command, *params|
            post(prefix, command, *params)
          end
          sleep Stalkerr::Const::FETCH_INTERVAL
        rescue Exception => e
          @log.error e.inspect
          e.backtrace.each { |l| @log.error "\t#{l}" }
          sleep 10
        end
      end
    end
  end

  private

  def target
    @target ||= @class_name.constantize.new(@username, @password)
  end
end
