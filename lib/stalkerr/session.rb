require 'ostruct'
require 'time'
require 'net/irc'
require 'stalkerr'
Dir["#{File.dirname(__FILE__)}/target/*.rb"].each { |p| require p }

class Stalkerr::Session < Net::IRC::Server::Session

  def server_name
    'Stalkerr'
  end

  def server_version
    Stalkerr::VERSION
  end

  def initialize(*args)
    super
    @debug = args.last.debug
    @channels = @threads = @targets = {}
    Dir["#{File.dirname(__FILE__)}/target/*.rb"].each do |path|
      name = File.basename(path, '.rb')
      @channels.merge!(name.to_sym => "##{name}")
    end
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
    create_worker(m.params)
  end

  def on_part(m)
    super
    kill @threads[m.params.first]
  end

  def on_disconnected
    super
    kill_all
  end

  private

  def create_worker(params)
    channels = params[0].split(',')
    keys = params[1].split(',')
    channels.each_with_index.map { |v, i| [v, keys[i]] }.each do |channel, key|
      guard auth_data(key).merge(channel: channel)
    end
  end

  def auth_data(key)
    id, pw = key.match(/(.*?):(.*)/).to_a.pop(2)
    { username: id, password: pw }
  end

  def guard(params)
    post params[:username], JOIN, params[:channel]
    @threads[params[:channel]] = Thread.start(target params) do |service|
      loop do
        begin
          service.stalking do |prefix, command, *params|
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

  def target(params)
    ch = params[:channel]
    class_name = "Stalkerr::Target::#{@channels.invert[ch].capitalize}"
    unless @targets[ch].is_a?(class_name.constantize)
      @targets[ch] = class_name.constantize.new(params[:username], params[:password])
    end
    @targets[ch]
  end

  def kill(thread)
    thread.kill if thread && thread.alive?
  end

  def kill_all
    @threads.each { |channel, thread| thread.kill if thread.alive? } rescue nil
  end
end
