require 'spec_helper'

describe "Bundle" do
  let(:project) {Factory :project}
  let(:bundle)  {Factory :bundle, project_id: project.id}

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

  describe "available features" do
    it "includes features attached to other bundles" do
      other_feature = Factory :feature,
        project_id: project.id, bundle_ids: ["hello"]
      bundle.available_features.should include other_feature
    end

    it "includes features not attached to ANY bundle" do
      orphaned_feature = Factory :feature,
        project_id: project.id, bundle_ids: []
      bundle.available_features.should include orphaned_feature
    end

    it "excludes features attached to this bundle" do
      feature_in_the_bundle = Factory :feature,
        project_id: project.id, bundle_ids: [bundle.id]
      bundle.available_features.should_not include feature_in_the_bundle
    end
  end

  describe "features" do
    it "includes features that are attached to the bundle" do
      bundled_feature = Factory :feature,
        project_id: project.id, bundle_ids: [bundle.id]
      bundle.features.should include bundled_feature
    end

    it "excludes features that are not attached" do
      other_feature = Factory :feature, project_id: project.id
      bundle.features.should_not include other_feature
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

  describe "features_needing_discussion" do
    let(:f) {Factory :feature, bundle_ids: [bundle.id], estimate: nil}
    before(:each) {f}
    it "includes features needs_discussione" do
      bundle.features_needing_discussion.should include f
    end

    it "sorts features that needs discussion" do
      f2 = Factory :feature, bundle_ids: [bundle.id], estimate: nil
      f3 = Factory :feature, bundle_ids: [bundle.id], estimate: nil
      bundle.features_needing_discussion.should == [f, f2, f3]
    end
  end

  describe "features_ready_for_estimate" do
    let(:f) { Factory :feature, bundle_ids: [bundle.id], ready_for_estimate_at: Time.now, estimate: nil }
    before(:each) {f}
    it "includes features ready_for_estimate" do
      bundle.features_ready_for_estimate.should include f
    end

    it "sorts features that are ready for estimate" do
      f2 = Factory :feature, bundle_ids: [bundle.id], ready_for_estimate_at: Time.now, estimate: nil
      f3 = Factory :feature, bundle_ids: [bundle.id], ready_for_estimate_at: Time.now, estimate: nil
      bundle.features_ready_for_estimate.should == [f, f2, f3]
    end
  end

  describe "features_ready_to_schedule" do
    let(:f) {Factory :feature, bundle_ids: [bundle.id], estimate: 3}
    before(:each) {f}
    it "includes features with estimates" do
      bundle.features_ready_to_schedule.should include f
    end
    it "sorts features that are ready for schedule" do
      f2 = Factory :feature, bundle_ids: [bundle.id], estimate: 3
      f3 = Factory :feature, bundle_ids: [bundle.id], estimate: 3
      bundle.features_ready_to_schedule.should == [f, f2, f3]
    end
  end
end