require 'time'
require 'net/irc'
require 'octokit'
require 'net/http'
require 'string-irc'
require 'stalkerr'

module Stalkerr::Target
  class Github
    include Net::IRC::Constants

    HOST = 'https://github.com'
    CHANNEL = '#github'

    def initialize(username, password)
      @username = username
      @password = password
      @last_event_id = nil
    end

    def client
      if !@client || @client && !@client.authenticated?
        @client = Octokit.new(login: @username, password: @password)
      end
      @client
    end

    def stalking(&post)
      @post = post
      client.received_events(@username).sort_by(&:id).reverse_each { |event|
        if @last_event_id.nil?
          next if Time.now.utc - Stalkerr::Const::ROLLBACK_SEC >= Time.parse(event.created_at).utc
        else
          next if @last_event_id >= event.id
        end
        result = parse(event)
        @last_event_id = result if result != false
      }
    end

    def parse(event)
      obj = event.payload
      header = status = title = link = ''
      body = []
      none_repository = false
      notice_body = false

      case event.type
      when 'CommitCommentEvent'
        status = "commented on commit"
        title = "#{obj.comment.path}"
        body = body + split_for_comment(obj.comment.body)
        link = obj.comment.html_url
      when 'PullRequestReviewCommentEvent'
        status = "commented on pull request"
        if obj.comment.pull_request_url
          pull_id = obj.comment.pull_request_url.match(/\/pulls\/([0-9]+)/)[1]
          pull = client.pull(event.repo.name, pull_id)
          title = "#{pull.title}: #{obj.comment.path}"
        else
          title = obj.comment.path
        end
        body = body + split_for_comment(obj.comment.body)
        link = obj.comment.html_url
      when 'IssueCommentEvent'
        if obj.action == 'created'
          status = "commented on issue ##{obj.issue.number}"
          title = obj.issue.title
        else
          status = "#{obj.action} issue comment"
        end
        body = body + split_for_comment(obj.comment.body)
        link = obj.comment.html_url
      when 'IssuesEvent'
        status = "#{obj.action} issue ##{obj.issue.number}"
        title = obj.issue.title
        body = body + split_for_comment(obj.issue.body)
        body << "assignee: #{obj.issue.assignee.login}" if obj.issue.assignee
        body << "milestone: #{obj.issue.milestone.title}[#{obj.issue.milestone.state}]" if obj.issue.milestone
        link = obj.issue.html_url
      when 'PullRequestEvent'
        status = "#{obj.action} pull request ##{obj.number}"
        title = obj.pull_request.title
        body = body + split_for_comment(obj.pull_request.body)
        link = obj.pull_request.html_url
      when 'PushEvent'
        notice_body = true
        status = "pushed to #{obj.ref.gsub('refs/heads/', '')}"
        obj.commits.each do |commit|
          verbose_commit = client.commit(event.repo.name, commit.sha)
          name = verbose_commit.author ? verbose_commit.author.login : commit.author.name
          url = "#{HOST}/#{event.repo.name}/commit/#{commit.sha}"
          line = "#{StringIrc.new(name).silver}: #{commit.message}"
          line << " - #{StringIrc.new(shorten url).blue}"
          body = body + split_for_comment(line)
        end
        link = "#{HOST}/#{event.repo.name}"
      when 'CreateEvent'
        if obj.ref_type.eql? 'repository'
          none_repository = true
          status = "created repository"
          title = event.repo.name
          title = "#{title}: #{obj.description}" if obj.description
        else
          status = "created #{obj.ref_type}:#{obj.ref}"
          title = obj.description
        end
        link = "#{HOST}/#{event.repo.name}"
      when 'DeleteEvent'
        status = "deleted #{obj.ref_type}:#{obj.ref}"
        link = "#{HOST}/#{event.repo.name}"
      when 'DownloadEvent'
        status = "download #{obj.name}"
        title = obj.description
        link = obj.html_url
      when 'ForkEvent'
        status = "forked #{obj.forkee.full_name} [#{obj.forkee.language}]"
        title = obj.forkee.description
        link = obj.forkee.html_url
      when 'TeamAddEvent'
        status = "add team"
        title = obj.team.name
      when 'WatchEvent'
        none_repository = true
        status = "#{obj.action} repository"
        title = event.repo.name
        link = "#{HOST}/#{event.repo.name}"
      when 'FollowEvent'
        none_repository = true
        notice_body = true
        user = obj.target
        status = "followed"
        title = user.login
        title = "#{title} (#{user.name})" if user.name && user.name != ''
        profile = ["#{StringIrc.new('repos').silver}: #{user.public_repos}"]
        profile << "#{StringIrc.new('followers').silver}: #{user.followers}"
        profile << "#{StringIrc.new('following').silver}: #{user.following}"
        profile << "#{StringIrc.new('location').silver}: #{user.location && user.location != '' ? user.location : '-'}"
        profile << "#{StringIrc.new('company').silver}: #{user.company && user.company != '' ? user.company : '-'}"
        profile << "#{StringIrc.new('bio').silver}: #{user.bio && user.bio != '' ? user.bio : '-'}"
        profile << "#{StringIrc.new('blog').silver}: #{user.blog && user.blog != '' ? user.blog : '-'}"
        body << profile.join(', ')
        link = "#{HOST}/#{user.login}"
      when 'MemberEvent'
        user = obj.member
        status = "#{obj.action} member"
        title = user.login
        link = "#{HOST}/#{user.login}"
      when 'GistEvent'
        none_repository = true
        status = "#{obj.action}d gist"
        title = obj.gist.description unless obj.gist.description.eql? ''
        link = obj.gist.html_url
      when 'DownloadEvent',
           'ForkApplyEvent',
           'GollumEvent',
           'PublicEvent'
        return false
      end

      nick = event.actor.login
      unless status.eql? ''
        color = case
                when status.include?('created') then :pink
                when status.include?('commented') then :yellow
                when status.include?('pushed') then :lime
                when status.include?('forked') then :orange
                when status.include?('closed') then :brown
                when status.include?('deleted') then :red
                when status.include?('started') then :rainbow
                when status.include?('followed') then :seven_eleven
                else :aqua
                end
        header = StringIrc.new(status).send(color)
        header = "(#{event.repo.name}) #{header}" unless none_repository
      end
      header = "#{header} #{title}" unless title.eql? ''
      header = "#{header} - #{StringIrc.new(shorten link).blue}" unless link.eql? ''

      @post.call nick, NOTICE, CHANNEL, header unless header.eql? ''
      mode = notice_body ? NOTICE : PRIVMSG
      body.each { |b| @post.call nick, mode, CHANNEL, b } unless body.eql? ''
      event.id
    end

    def split_for_comment(string)
      return [] unless string.is_a? String
      string.split(/\r\n|\n/).map { |v| v unless v.eql? '' }.compact
    end

    def shorten(url)
      Net::HTTP.start('git.io', 80) do |http|
        request = Net::HTTP::Post.new '/'
        request.content_type = 'application/x-www-form-urlencoded'
        query = Hash.new.tap { |h| h[:url] = url }
        request.body = URI.encode_www_form(query)
        response = http.request(request)
        response.key?('Location') ? response["Location"] : url
      end
    end
  end
end
