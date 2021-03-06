require 'helper'

describe Stalkerr::Target::Github do
  let(:username) { 'jack' }
  let(:password) { 'nicholson' }
  let(:path) { 'octokit_client/received_events' }
  before { @github = described_class.new(username, password) }

  describe '#initialize' do
    subject { @github }

    it { expect(subject.instance_variable_get :@username).to eq username }
    it { expect(subject.instance_variable_get :@password).to eq password }
    it { expect(subject.instance_variable_get :@last_event_id).to be_nil }
  end

  describe '#client' do
    subject { @github.client }

    it { expect(subject).to be_an_instance_of(Octokit::Client) }

    context 'when call a second time' do
      before { @id = @github.client.object_id }
      it { expect(subject.object_id).to eq @id }
    end

    context 'when not authenticated' do
      before do
        allow_any_instance_of(Octokit::Client).to receive(:token_authenticated?).and_return(false)
        @id = @github.client.object_id
      end
      it { expect(subject.object_id.eql? @id).to be_falsy }
    end
  end

  describe '#stalking' do
    let(:parse_result) { { event_id: 123456789 } }

    before do
      allow(@github).to receive(:parse).and_return(parse_result)
      allow(@github).to receive(:posts).and_return(nil)
    end

    subject do
      @github.stalking do |prefix, command, *params|
        post(prefix, command, *params)
      end
    end

    it 'return is array' do
      VCR.use_cassette 'octokit_client/received_events', match_requests_on: [:path] do
        expect(subject).to be_an_instance_of(Array)
      end
    end
  end

  describe '#parse' do
    before do
      @event = VCR.use_cassette path, match_requests_on: [:path] do
        @github.client.received_events(username).sort_by(&:id).map { |e|
          e if e.type == event_type
        }.compact.last
      end
    end

    subject { @github.parse(@event) }

    context 'issues event' do
      let(:event_type) { 'IssuesEvent' }

      it 'matched status format' do
        regex = /(created|closed) issue #[0-9]+/
        expect(subject[:status].to_s).to match regex
      end
    end

    context 'issue comment event' do
      let(:event_type) { 'IssueCommentEvent' }

      it 'matched status format' do
        regex = /(commented on issue #[0-9]+|deleted issue comment)/
        expect(subject[:status].to_s).to match regex
      end
    end

    context 'pull request event' do
      let(:event_type) { 'PullRequestEvent' }

      it 'matched status format' do
        regex = /(created|closed) pull request #[0-9]+/
        expect(subject[:status].to_s).to match regex
      end
    end

    context 'push event' do
      let(:event_type) { 'PushEvent' }

      it 'matched status format' do
        VCR.use_cassette 'octokit_client/commit', match_requests_on: [:path] do
          regex = /pushed to /
          expect(subject[:status].to_s).to match regex
        end
      end

      it 'noticeable' do
        VCR.use_cassette 'octokit_client/commit', match_requests_on: [:path] do
          expect(subject[:notice]).to be_truthy
        end
      end
    end
  end

  describe '#shorten' do
    let(:url) { 'https://github.com/linyows/stalkerr' }
    let(:short_url) { 'http://git.io/CSRjYA' }
    let(:api) { 'http://git.io/' }

    before { @github = described_class.new('user', 'password') }

    it 'request the correct resource' do
      VCR.use_cassette 'gitio/response' do
        res = @github.shorten(url)
        expect(res).to eq(short_url)
      end
    end
  end
end
