require 'helper'

describe Stalkerr::Target::Github do
  let(:username) { 'jack' }
  let(:password) { 'nicholson' }
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
        Octokit::Client.any_instance.stub(:authenticated?).and_return(false)
        @id = @github.client.object_id
      end
      it { expect(subject.object_id.eql? @id).to be_false }
    end
  end

  describe '#stalking' do
    let(:parse_result) { { event_id: 123456789 } }

    before do
      @github.stub(:parse).and_return(parse_result)
      @github.stub(:posts).and_return(nil)
    end

    subject do
      @github.stalking do |prefix, command, *params|
        post(prefix, command, *params)
      end
    end

    it 'return is array' do
      VCR.use_cassette 'octokit_client/received_events', :match_requests_on => [:path] do
        expect(subject).to be_an_instance_of(Array)
      end
    end
  end

  describe '#parse' do
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
