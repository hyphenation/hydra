require 'spec_helper'

describe Hydra do
  describe '.count' do
    it "counts" do
      hydra = Hydra.new
      hydra.ingest(['a', 'b', 'c'])
      expect(hydra.count).to eq 3
    end
  end
end
