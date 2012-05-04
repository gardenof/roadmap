 require 'spec_helper'

describe BundlesController do
  include BilgePump::Specs

  model_scope [:project]
  model_class Bundle

  def attributes_for_create
    { name: "Create Name"}
  end

  def attributes_for_update
    { name: "Update Name"}
  end


  describe "show" do
    let(:project) {Factory :project}
    let(:bundle)  {Factory :bundle, project_id: project.id}

    let (:show_params) {
      {
        project_id: project.to_param,
        id: bundle.to_param
      }
    }

    describe "@available_features" do
      it "includes features attached to other bundles" do
        other_feature = Factory :feature,
          project_id: project.id, bundle_ids: ["hello"]
        get :show, show_params
        assigns(:available_features).should include other_feature
      end

      it "includes features not attached to ANY bundle" do
        orphaned_feature = Factory :feature,
          project_id: project.id, bundle_ids: []
        get :show, show_params
        assigns(:available_features).should include orphaned_feature
      end

      it "excludes features attached to this bundle" do
        feature_in_the_bundle = Factory :feature,
          project_id: project.id, bundle_ids: [bundle.id]
        get :show, show_params
        assigns(:available_features).should_not include feature_in_the_bundle
      end
    end

    describe "@attached_features" do
      it " includes features that are attached to the bundle" do
        bundled_feature = Factory :feature,
          project_id: project.id, bundle_ids: [bundle.id]
        get :show, show_params
        assigns(:attached_features).should include bundled_feature
      end

      it "excludes features that are not attached" do
        other_feature = Factory :feature, project_id: project.id
        get :show, show_params
        assigns(:attached_features).should_not include other_feature
      end
    end
  end

  describe "schedule action" do
    let (:project) { Factory :project}
    let (:bundle) { Factory :bundle, project_id: project.id }
    let (:schedule_params) {
      {
        project_id: bundle.project.to_param,
        id: bundle.to_param
      }
    }

    it "works" do
      post :schedule, schedule_params
      response.should be_redirect
    end

    def bundled_feature
      Factory :feature, {
        story_id: nil,
        bundle_ids: [bundle.id],
        project_id: bundle.project.id
      }
    end

    let (:new_story) {
      Factory.build :tracker_story
    }

    it "updates all the bundle's features with story attrs" do
      feature1 = bundled_feature
      feature2 = bundled_feature
      TrackerIntegration.stub(:create_feature_in_tracker).and_return(new_story)

      post :schedule, schedule_params

      [feature1, feature2].each do |f|
        f.reload
        f.story_id.should == new_story.id
      end
    end

    it "calls tracker once for each feature in the bundle" do
      feature_count = rand(10)
      feature_count.times { |i| bundled_feature }
      TrackerIntegration.should_receive(:create_feature_in_tracker).exactly(feature_count).times.and_return(new_story)

      post :schedule, schedule_params
    end

  end
end