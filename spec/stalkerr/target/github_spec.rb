require 'helper'

describe Stalkerr::Target::Github do

  describe '#shorten' do
    let(:url) { 'https://github.com/linyows/stalkerr' }
    let(:short_url) { 'http://git.io/CSRjYA' }
    let(:api) { 'http://git.io/' }

    before { @github = described_class.new('user', 'password') }

    it 'should request the correct resource' do
       VCR.use_cassette 'gitio/response' do
          res = @github.shorten(url)
          expect(res).to eq(short_url)
       end
    end
  end
end
