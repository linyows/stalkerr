require 'time'
require 'net/irc'
require 'octokit'
require 'net/http'
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
        @client = Octokit.new(login: @username, access_token: @password)
      end
      @client
    end

    def stalking(&post)
      @post = post
      client.received_events(@username).sort_by(&:id).reverse_each { |event|
        if @last_event_id.nil?
          time = Time.now.utc - Stalkerr::Const::ROLLBACK_SEC
          next if time >= Time.parse(event.created_at).utc
        else
          next if @last_event_id.to_i >= event.id.to_i
        end
        next unless result = parse(event)
        posts(result)
        @last_event_id = result[:event_id]
      }
    end

    def parse(event)
      obj = event.payload
      repository = event.repo.name

      status = title = link = ''
      body = []
      notice = false

      case event.type
      when 'CommitCommentEvent'
        status = "commented on commit"
        title = "#{obj.comment.path}"
        body = obj.comment.body.split_by_crlf if obj.comment.body
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
        body = obj.comment.body.split_by_crlf if obj.comment.body
        link = obj.comment.html_url
      when 'IssueCommentEvent'
        if obj.action == 'created'
          status = "commented on issue ##{obj.issue.number}"
          title = obj.issue.title
        else
          status = "#{obj.action} issue comment"
        end
        body = obj.comment.body.split_by_crlf if obj.comment.body
        link = obj.comment.html_url
      when 'IssuesEvent'
        status = "#{obj.action} issue ##{obj.issue.number}"
        title = obj.issue.title
        body = obj.issue.body.split_by_crlf if obj.issue.body
        body << "assignee: #{obj.issue.assignee.login}" if obj.issue.assignee
        body << "milestone: #{obj.issue.milestone.title}[#{obj.issue.milestone.state}]" if obj.issue.milestone
        link = obj.issue.html_url
      when 'PullRequestEvent'
        status = "#{obj.action} pull request ##{obj.number}"
        title = obj.pull_request.title
        body = obj.pull_request.body.split_by_crlf if obj.pull_request.body
        link = obj.pull_request.html_url
      when 'PushEvent'
        notice = true
        status = "pushed to #{obj.ref.gsub('refs/heads/', '')}"
        obj.commits.each do |commit|
          verbose_commit = client.commit(event.repo.name, commit.sha)
          name = verbose_commit.author ? verbose_commit.author.login : commit.author.name
          url = "#{HOST}/#{event.repo.name}/commit/#{commit.sha}"
          line = "#{name.to_irc_color.silver}: #{commit.message}"
          line << " - #{shorten(url).to_irc_color.blue}"
          body = line.split_by_crlf
        end
        link = "#{HOST}/#{event.repo.name}"
      when 'CreateEvent'
        if obj.ref_type.eql? 'repository'
          repository = nil
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
        repository = nil
        status = "#{obj.action} repository"
        title = event.repo.name
        link = "#{HOST}/#{event.repo.name}"
      when 'FollowEvent'
        repository = nil
        notice = true
        user = obj.target
        status = "followed"
        title = user.login
        title = "#{title} (#{user.name})" if user.name && user.name != ''
        profile = ["#{'repos'.to_irc_color.silver}: #{user.public_repos}"]
        profile << "#{'followers'.to_irc_color.silver}: #{user.followers}"
        profile << "#{'following'.to_irc_color.silver}: #{user.following}"
        profile << "#{'location'.to_irc_color.silver}: #{user.location && user.location != '' ? user.location : '-'}"
        profile << "#{'company'.to_irc_color.silver}: #{user.company && user.company != '' ? user.company : '-'}"
        profile << "#{'bio'.to_irc_color.silver}: #{user.bio && user.bio != '' ? user.bio : '-'}"
        profile << "#{'blog'.to_irc_color.silver}: #{user.blog && user.blog != '' ? user.blog : '-'}"
        body << profile.join(', ')
        link = "#{HOST}/#{user.login}"
      when 'MemberEvent'
        user = obj.member
        status = "#{obj.action} member"
        title = user.login
        link = "#{HOST}/#{user.login}"
      when 'GistEvent'
        repository = nil
        status = "#{obj.action}d gist"
        title = obj.gist.description unless obj.gist.description.eql? ''
        link = obj.gist.html_url
      when 'DownloadEvent',
           'ForkApplyEvent',
           'GollumEvent',
           'PublicEvent'
        return false
      end

      unless status.empty?
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
        status = status.to_irc_color.send(color)
      end

      unless body.eql? ''
        if body.length > 20
          body_footer = body[-3..-1]
          body = body[0...15]
          body << '-----8<----- c u t -----8<-----'
          body = body + body_footer
        end
      end

      {
        event_id: event.id,
        nick: event.actor.login,
        status: status,
        repository: repository,
        link: link,
        title: title,
        body: body,
        notice: notice
      }
    end

    def posts(p)
      header = ''
      header = "(#{p[:repository]}) #{p[:status]}" unless p[:repository].eql? ''
      header = "#{header} #{p[:title]}" unless p[:title].eql? ''
      header = "#{header} - #{shorten(p[:link]).to_irc_color.blue}" unless p[:link].eql? ''

      unless header.empty?
        @post.call p[:nick], NOTICE, CHANNEL, header
      end

      if !p[:body].nil? && !p[:body].empty?
        body.each do |line|
          mode = p[:notice] ? NOTICE : PRIVMSG
          # maximum line length 512
          # http://www.mirc.com/rfc2812.html
          line.each_char.each_slice(512) do |string|
            @post.call p[:nick], mode, CHANNEL, string.join
            sleep 1
          end
        end
      end
    end

    def shorten(url)
      Net::HTTP.start('git.io', 80) do |http|
        request = Net::HTTP::Post.new '/'
        request.content_type = 'application/x-www-form-urlencoded'
        query = Hash.new.tap { |h| h[:url] = url }
        request.body = URI.encode_www_form(query)
        response = http.request(request)
        response.key?('Location') ? response['Location'] : url
      end
    end
  end
end
