require 'spec_helper'

describe Stalkerr::Extensions::String do

  describe '#constantize' do
    it { expect('String'.constantize).to eq(String) }
  end
end
