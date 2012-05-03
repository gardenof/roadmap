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
    it "works" do
      project = Factory :project
      bundle = Factory :bundle, project_id: project.id

      post :schedule, {
        project_id: bundle.project.to_param,
        id: bundle.to_param
      }

      response.should be_redirect
    end

    def bundled_feature(bundle)
      Factory :feature, {
        story_id: nil,
        bundle_ids: [bundle.id],
        project_id: bundle.project.id
      }
    end

    it "updates all the bundle's features with their new IDs" do
      project = Factory :project
      bundle = Factory :bundle, project_id: project.id

      feature1 = bundled_feature(bundle)
      feature2 = bundled_feature(bundle)

      new_story = Factory.build :tracker_story
      TrackerIntegration.stub(:create_feature_in_tracker).and_return(new_story)

      # post project_id, bundle_id
      post :schedule, {
        project_id: bundle.project.to_param,
        id: bundle.to_param
      }

      [feature1, feature2].each do |f|
        f.reload
        f.story_id.should == new_story.id
      end
    end

    xit "calls tracker once for each feature in the bundle" do
    end

  end
end