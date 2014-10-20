require 'helper'

describe Stalkerr::Extensions::String do

  describe '#constantize' do
    it { expect('String'.constantize).to eq(String) }
  end

  describe '.camerize' do
    it 'returns camelcase' do
      expect('foo_bar_baz'.camerize).to eq 'FooBarBaz'
    end
  end

  describe '#split_by_crlf' do
    let(:sentence) {
      <<-RUBY
        That lucid breeze in Ihatov,
        Blue sky that has coolness at the bottom even in summer,
        Morio which has been decorated with beautiful forest,
        grass wave shines garishly in suburb.
      RUBY
    }
    let(:empty) { '' }
    it { expect(sentence.split_by_crlf.class).to eq(Array) }
    it { expect(sentence.split_by_crlf.count).to eq(4) }
    it { expect(empty.split_by_crlf).to eq([]) }
  end

  describe '#to_irc_color' do
    it { expect('String'.to_irc_color.class).to eq(StringIrc) }
  end
end
