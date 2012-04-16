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
end