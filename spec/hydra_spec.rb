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

  describe '.dump' do
    let(:device) { double(:output).as_null_object }

    it "dumps a string", focus: true do
      hydra = Hydra.new
      hydra.ingest(['apple', 'orange', 'lemon'])
      expect(device).to receive :pp
      hydra.dump(device)
    end
  end
  # TODO ingest with numbers, ingest_file (with %’s?), etc.
end
