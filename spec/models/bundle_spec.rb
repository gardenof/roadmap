require 'spec_helper'

describe "Bundle" do
  let(:bundle) { Factory :bundle }

  describe"estimates_total" do

    let(:create_features) {
      3.times do
        Factory :feature, estimate: 5, bundle_ids: [bundle.id]
      end
    }

    it "totals correctly" do
      create_features
      bundle.estimates_total.should == 15
    end

    it "ignores negative estimates" do
      create_features
      Factory :feature, estimate: -2, bundle_ids: [bundle.id]
      bundle.estimates_total.should == 15
    end
  end

  describe "unestimated_count" do
    let (:create_nil_features) {
      2.times do
        Factory :feature, estimate: nil, bundle_ids: [bundle.id]
      end
    }

    it "counts correctly" do
      create_nil_features
      bundle.unestimated_count.should == 2
    end

    it "only counts unestimated features" do
      Factory :feature, estimate: 100, bundle_ids: [bundle.id]
      create_nil_features

      bundle.unestimated_count.should == 2
    end
  end
end