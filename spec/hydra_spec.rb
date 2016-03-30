require 'spec_helper'

describe Knuckle do
  describe '#digit' do
    it "returns a digit" do
      knuckle = Knuckle.new('r', 3)
      expect(knuckle.digit).to eq 3
    end

    describe '#letter' do
      it "returns a letter" do
        knuckle = Knuckle.new('r')
        expect(knuckle.letter).to eq 'r'
      end
    end
  end
end

describe Hydra do
  let(:hydra)  { Hydra.new }
  describe '#count' do
    it "counts" do
      hydra.ingest(['a', 'b', 'c'])
      expect(hydra.count).to eq 3
    end
  end

  describe '#ingest' do
    it "works with a single word" do
      hydra.ingest('bac')
      expect(hydra.count).to eq 1
    end

    it "works with an array of words" do
      hydra.ingest(['democrat', 'democracy', 'democratic'])
      expect(hydra.count).to eq 3
    end
  end

  describe '#digest' do
    it "returns the list of words" do
      hydra.ingest(['orange', 'yellow', 'red'])
      expect(hydra.digest).to eq ['orange', 'red', 'yellow']
    end
  end

  describe '#dump' do
    let(:device) { double(:output).as_null_object }

    it "dumps a string" do
      hydra.ingest(['apple', 'orange', 'lemon'])
      expect(device).to receive :pp
      hydra.dump(device)
    end
  end
  # TODO ingest with numbers, ingest_file (with %’s?), etc.
end
