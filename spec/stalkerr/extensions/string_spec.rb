require 'helper'

describe Stalkerr::Extensions::String do
  describe '.constantize' do
    it 'returns class' do
      expect('String'.constantize).to eq String
    end
  end

  describe '.camerize' do
    it 'returns camelcase' do
      expect('foo_bar_baz'.camerize).to eq 'FooBarBaz'
    end
  end

  describe '.split_by_crlf' do
    let(:sentence) {
    }

    it 'returns array' do
      sentence = <<-STRING.gsub(/^\s+/, '')
        That lucid breeze in Ihatov,
        Blue sky that has coolness at the bottom even in summer,
        Morio which has been decorated with beautiful forest,
        grass wave shines garishly in suburb.
      STRING

      expect(sentence.split_by_crlf).to eq(
        [
          'That lucid breeze in Ihatov,',
          'Blue sky that has coolness at the bottom even in summer,',
          'Morio which has been decorated with beautiful forest,',
          'grass wave shines garishly in suburb.'
        ]
      )
    end

    context 'when empty string' do
      it 'returns empty array' do
        expect(''.split_by_crlf).to eq []
      end
    end
  end

  describe '.to_irc_color' do
    it 'returns StringIrc' do
      expect('String'.to_irc_color.class).to eq StringIrc
    end
  end
end
