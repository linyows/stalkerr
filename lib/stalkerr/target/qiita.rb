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
      @last_markers = {
        followings: {
          stock: nil,
          item: nil,
          user: nil
        },
        tag_items: nil
      }
    end

    def client
      @client ||= ::Qiita.new(url_name: @username, password: @password)
    end

    def stalking(&post)
      return if !@last_fetched_at.nil? && Time.now.utc < @last_fetched_at + INTERVAL

      @post = post

      followings = client.user_following_users(@username).map { |u| u.url_name }.compact
      followings.each do |user|
        client.user_stocks(user).reverse_each { |obj|
          m = @last_markers[:followings][:stock]
          if !m.nil? && m == obj.uuid
            m = obj.uuid
            break
          end
          parse 'stock', [user, obj]
        }
        client.user_items(user).reverse_each { |obj|
          m = @last_markers[:followings][:stock]
          if !m.nil? && m == obj.uuid
            m = obj.uuid
            break
          end
          parse 'item', [user, obj]
        }
        client.user_following_users(user).reverse_each { |obj|
          m = @last_markers[:followings][:user]
          if !m.nil? && m == obj.url_name
            m = obj.url_name
            break
          end
          parse 'user', [user, obj]
        }
      end

      tags = client.user_following_tags(@username).map { |t| t.url_name }.compact
      items = tags.inject([]) { |arr, tag| arr + client.tag_items(tag) }.uniq
      items.each do |obj|
        m = @last_markers[:tag_items]
        if !m.nil? && m == obj.uuid
          m = obj.uuid
          break
        end
        parse 'item', [obj.user.url_name, obj]
      end
    end

    def parse(type, data)
      nick, obj = data
      header = status = title = link = ''
      body = []

      case type
      when 'stock'
        status = "stocked entry"
        color = :pink
        title = "#{obj.title}"
        body = split_for_body obj.raw_body
        link = obj.url
      when 'item'
        status = "new entry"
        color = :yellow
        title = "#{obj.title}"
        body = split_for_body obj.raw_body
        link = obj.url
      when 'user'
        status = "followed #{obj.url_name}"
        color = :rainbow
        link = "#{HOST}/users/#{obj.url_name}"
      end

      header = StringIrc.new(status).send(color)
      header = "#{header} #{title}" unless title.eql? ''
      header = "#{header} - #{StringIrc.new(link).blue}"

      @post.call nick, NOTICE, CHANNEL, header
      body.each { |b| @post.call nick, PRIVMSG, CHANNEL, b } unless body.eql? []
    end

    def split_for_body(string)
      return [] unless string.is_a?(String)
      string.split(/\r\n|\n/).map { |v| v unless v.eql? '' }.compact
    end
  end
end
