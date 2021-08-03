# frozen_string_literal: true

RSpec.describe WiseGopher::RawParam do
  describe "#to_s" do
    context "when argument is needed" do
      let(:result) { raw_param.to_s("id > 10") }

      context "when no option is given" do
        let(:raw_param) { described_class.new(:condition) }

        it "returns the correct string to interpolate" do
          expect(result).to eq("id > 10")
        end
      end

      context "when prefix is given" do
        let(:raw_param) { described_class.new(:condition, prefix: " AND ") }

        it "returns the correct string to interpolate" do
          expect(result).to eq(" AND id > 10")
        end
      end

      context "when suffix is given" do
        let(:raw_param) { described_class.new(:condition, suffix: " AND ") }

        it "returns the correct string to interpolate" do
          expect(result).to eq("id > 10 AND ")
        end
      end

      context "when argument is not given" do
        let(:raw_param) { described_class.new(:condition) }
        let(:result) { raw_param.to_s }

        it "raises an error" do
          expect { result }.to raise_error ArgumentError
        end
      end
    end

    context "when argument is not needed" do
      let(:result) { raw_param.to_s }

      context "when default value is given" do
        let(:raw_param) { described_class.new(:condition, default: "id = 42", prefix: "WHERE ", suffix: " AND ") }

        it "returns the correct string to interpolate" do
          expect(result).to eq("WHERE id = 42 AND ")
        end
      end

      context "when optional is true" do
        let(:raw_param) { described_class.new(:condition, optional: true, prefix: "don't add me", suffix: "me neither") }

        it "returns the correct string to interpolate" do
          expect(result).to eq("")
        end
      end
    end
  end
end
