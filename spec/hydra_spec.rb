require 'spec_helper'

# TODO Spec out .dump
describe Hydra do
  describe '.count' do
    it "counts" do
      hydra = Hydra.new
      hydra.ingest(['a', 'b', 'c'])
      expect(hydra.count).to eq 3
    end
  end

  describe '.ingest' do
    it "works with a single word" do
      hydra = Hydra.new
      hydra.ingest('bac')
      expect(hydra.count).to eq 1
    end

    it "works with an array of words" do
      hydra = Hydra.new
      hydra.ingest(['democrat', 'democracy', 'democratic'])
      expect(hydra.count).to eq 3
    end
  end
end
