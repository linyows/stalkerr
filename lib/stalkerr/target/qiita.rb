require 'time'
require 'net/irc'
require 'qiita'
require 'net/http'
require 'string-irc'
require 'stalkerr'

module Stalkerr::Target
  class Qiita
    include Net::IRC::Constants

    HOST = 'http://qiita.com'
    CHANNEL = '#qiita'
    INTERVAL = 60 * 10

    def initialize(username, password)
      @username = username
      @password = password
      @last_fetched_at = nil
      @marker = nil
    end

    def client
      @client ||= ::Qiita.new(url_name: @username, password: @password)
    end

    def stalking(&post)
      return if @last_fetched_at && Time.now.utc < @last_fetched_at + INTERVAL
      @last_fetched_at = Time.now.utc

      @post = post
      stocked_items = posted_items = []
      stocks = {}

      followings = client.user_following_users(@username).map { |u| u.url_name }.compact
      followings.each do |user|
        begin
          stocks[user] = client.user_stocks(user)
          stocked_items = stocked_items + stocks[user]
        rescue => e
          nil
        end
        begin
          posted_items = posted_items + client.user_items(user)
        rescue => e
          nil
        end
      end

      tags = client.user_following_tags(@username).map { |t| t.url_name }.compact
      new_items = tags.inject([]) { |arr, tag| arr + client.tag_items(encoder tag) }

      items = (stocked_items + posted_items + new_items).uniq
      items[0...30].sort_by(&:id).each do |obj|
        next if @marker && @marker >= obj.id
        type = 'new'
        nick = obj.user.url_name
        case
        when stocked_items.include?(obj)
          type = 'stock'
          stocks.each { |user, users_stocks|
            nick = user and break if users_stocks.include?(obj)
          }
        when posted_items.include?(obj)
          type = 'post'
        end
        parse type, [nick, obj]
        @marker = obj.id
      end
    end

    def parse(type, data)
      nick, obj = data
      header = status = title = link = ''
      body = []
      notice_body = false

      case type
      when 'stock'
        status = "stocked entry"
        color = :pink
      when 'post'
        status = "posted entry"
        color = :yellow
      when 'new'
        status = "new entry"
        color = :aqua
        notice_body = true
      end
      title = "#{obj.title}"
      body = split_for_body obj.raw_body
      link = obj.url

      header = StringIrc.new(status).send(color)
      header = "#{header} #{title}" unless title.eql? ''
      header = "#{header} - #{StringIrc.new(link).blue}"

      @post.call simple(nick), NOTICE, CHANNEL, header
      mode = notice_body ? NOTICE : PRIVMSG
      body.each { |b| @post.call simple(nick), mode, CHANNEL, b } unless body.eql? []
    end

    def split_for_body(string)
      return [] unless string.is_a?(String)
      string.split(/\r\n|\n/).map { |v| v unless v.eql? '' }.compact
    end

    def simple(string)
      string.gsub('@github', '')
    end

    def encoder(string)
      URI.encode(string).gsub('.', '%2e')
    end
  end
end
