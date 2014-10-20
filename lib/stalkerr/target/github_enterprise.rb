require 'stalkerr/target/github'

module Stalkerr::Target
  class GithubEnterpriseError < GithubError; end

  class GithubEnterprise < Github
    def channel
      ENV['GITHUB_ENTERPRISE_CHANNEL'] || '#github_enterprise'
    end

    def client
      if !@client || @client && !@client.token_authenticated?
        @client = Octokit::Client.new(
          access_token: @password,
          api_endpoint: _api_endpoint,
          web_endpoint: _web_endpoint
        )
      end
      @client
    end

    private

    def _web_endpoint
      ENV['GITHUB_ENTERPRISE_WEB_ENDPOINT'] ||
        raise(GithubEnterpriseError, 'web endpoint is nil')
    end

    def _api_endpoint
      ENV['GITHUB_ENTERPRISE_API_ENDPOINT'] ||
        raise(GithubEnterpriseError, 'api endpoint is nil')
    end
  end
end
