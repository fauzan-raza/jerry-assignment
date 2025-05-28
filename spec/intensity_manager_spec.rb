require "intensity_manager"

RSpec.describe IntensityManager do
    subject(:manager) { described_class.new }

    describe "#set" do
        it "sets intensity in a given range" do
            expect(manager.set(0, 10, 5)).to eq({ 0 => 5, 10 => 0 })
        end

        it "overwrites existing set range" do
            manager.set(0, 10, 5)
            manager.set(0, 10, 3)
            expect(manager.intensities).to eq({ 0 => 3, 10 => 0 })
        end
    end

    describe "#add" do
        it "adds intensity to a range" do
            manager.set(0, 10, 5)
            expect(manager.add(5, 15, 3)).to eq({ 0 => 5, 5 => 8, 10 => 3, 15 => 0 })
        end

        it "applies multiple adds correctly" do
            manager.set(0, 10, 1)
            manager.add(0, 5, 2)
            manager.add(5, 10, 3)
            expect(manager.intensities).to eq({ 0 => 3, 5 => 4, 10 => 0 })
        end

        it "handles negative intensity in add" do
            manager.set(0, 10, 5)
            manager.add(0, 5, -2)
            expect(manager.intensities).to eq({ 0 => 3, 5 => 5, 10 => 0 })
        end
    end

    describe "#intensities" do
        it "returns the internal intensity hash" do
            manager.set(0, 10, 2)
            expect(manager.intensities).to eq({ 0 => 2, 10 => 0 })
        end
    end

    describe "overlapping ranges" do
        it "adds to overlapping range correctly" do
            manager.set(0, 10, 2)
            manager.add(5, 15, 3)
            expect(manager.intensities).to eq({ 0 => 2, 5 => 5, 10 => 3, 15 => 0 })
        end
    end

    describe "edge cases" do
        it "raises error when from >= to" do
            expect { manager.set(10, 10, 5) }.to raise_error(ArgumentError)
        end

        it "raises error for non-integer input" do
            expect { manager.add("a", 10, 5) }.to raise_error(ArgumentError)
        end

        it "skips no-op zero add if empty" do
            expect(manager.add(0, 5, 0)).to eq({})
        end

        it "cleans up zero values unless they mark end of range" do
            manager.set(0, 10, 0)
            expect(manager.intensities).to eq({})
        end
    end
end
