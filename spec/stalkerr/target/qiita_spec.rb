require 'helper'

describe Stalkerr::Target::Qiita do
  let(:username) { 'jack@github' }
  let(:password) { 'nicholson' }
  before { @qiita = described_class.new(username, password) }

  describe '#initialize' do
    subject { @qiita }

    it { expect(subject.instance_variable_get :@username).to eq username }
    it { expect(subject.instance_variable_get :@password).to eq password }
    it { expect(subject.instance_variable_get :@last_fetched_at).to be_nil }
    it { expect(subject.instance_variable_get :@marker).to be_nil }
  end

  describe '#client' do
    it 'qiita client instance' do
      VCR.use_cassette 'qiita_client/login', match_requests_on: [:path] do
        expect(@qiita.client).to be_an_instance_of(Qiita::Client)
      end
    end
  end

  describe '#stalking' do
  end

  describe '#parse' do
  end

  describe '#shorten' do
  end
end
