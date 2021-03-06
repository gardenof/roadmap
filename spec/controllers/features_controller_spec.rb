require 'spec_helper'

describe FeaturesController do
  include BilgePump::Specs

  model_scope [:project]
  model_class Feature

  def attributes_for_create
    { name: "Created Feature" }
  end

  def attributes_for_update
    { name: "Updated Feature" }
  end
  let (:project) {Factory :project}
  describe "GET tagged" do


    it "returns 200 OK" do
      # /features/tagged/red
      get :tagged, project_id: project.id, value: "red"
      response.should be_success
    end

    it "accepts dots in params" do
      # /features/tagged/red.blue
      get :tagged, project_id: project.id, value: "red.blue"
      response.should be_success
    end

    it "assigns fetched features into @features" do
      red_feature1 = Factory :feature, labels: ["red"], project_id: project.id
      red_feature2 = Factory :feature, labels: ["red"], project_id: project.id
      blue_feature = Factory :feature, labels: ["blue"], project_id: project.id

      get :tagged, project_id: project.id, value: "red"
      assigns(:features).should == [red_feature1, red_feature2]
    end
  end

  describe "update" do
    let (:updatable_feature) {Factory :feature, name: "before update", project_id: project.id}
    let (:not_updatable_feature) {Factory :feature, story_id: 1123, project_id: project.id}
    let(:bundle) {
      Factory :bundle,
                       project_id: project.id,
                       ready_to_schedule_order: [],
                       ready_for_estimate_order: [],
                       needing_discussion_order: []
    }
    it "changes value" do
      updatable_feature
      put :update, project_id: project.to_param,
        id: updatable_feature.id,
        feature: {:name => "after update"}
      updatable_feature.reload.name.should == "after update"
    end

    it "redirecting correctly when updatable bundled feature" do
      put :update, project_id: project.to_param, id: updatable_feature.id, redirect_to_bundle_id: bundle.to_param
      assert_redirected_to project_bundle_path(project, bundle)
    end

    it "redirecting correctly when updatable feature" do
      put :update, project_id: project.to_param, :id => updatable_feature.id
      assert_redirected_to project_feature_path(project, updatable_feature)
    end

    it "redirecting correctly when not updatable feature and flash notice" do
      put :update, project_id: project.to_param, :id => not_updatable_feature.id
      assert_redirected_to project_feature_path(project, not_updatable_feature)
      flash.now[:notice].should_not be_nil
    end

    it "redirecting correctly when not updatable bundled feature and flash notice" do
      put :update, project_id: project.to_param, id: not_updatable_feature.id, redirect_to_bundle_id: bundle.to_param
      assert_redirected_to project_bundle_path(project, bundle)
      flash.now[:notice].should_not be_nil
    end

    it "stores feature BSON in appropriate array depending on which column it's in on bundles page" do
      feature_a = Factory :feature, bundle_ids: [bundle.id], estimate: nil, story_id: nil
      feature_b = Factory :feature, bundle_ids: [bundle.id], estimate: nil, story_id: nil
      feature_c = Factory :feature, bundle_ids: [bundle.id], ready_for_estimate_at: Time.now, estimate: nil, story_id: nil
      bundle.needing_discussion_order = [feature_a.id, feature_b.id]
      bundle.ready_for_estimate_order = [feature_c.id]
      bundle.save

      put :update, project_id: project.to_param,
                   id: feature_a.id,
                   redirect_to_bundle_id: bundle.to_param,
                   feature: {ready_for_estimate_at: Time.now}

      bundle.reload
      bundle.ready_for_estimate_order.should ==  [feature_c.id, feature_a.id ]
      bundle.needing_discussion_order.should == [feature_b.id]
    end
  end

  describe "schedule" do
    let (:new_story) {Factory.build :tracker_story}
    let (:bundle) {Factory :bundle, project_id: project.id}
    let (:feature_to_schedule) {Factory :feature, story_id: nil,
                                                  project_id: project.id,
                                                  bundle_ids: [bundle.id]}
    let (:params_without_bundle) {{project_id: project.id,
                                   feature_id: feature_to_schedule.id}}
    let (:params_with_bundle) {{project_id: project.id,
                                feature_id: feature_to_schedule.id,
                                bundle_id: bundle.id}}
    before :each do
      TrackerIntegration.stub(:create_feature_in_tracker).and_return(new_story)
    end

    it "creates the feature in tracker" do
      post :schedule, params_without_bundle
      assigns(:feature).story_id.should_not be_nil
    end

    it "redirecting to feature if no bundle in params" do
      post :schedule, params_without_bundle
      assert_redirected_to project_feature_path(project, feature_to_schedule)
    end

    it "redirecting to bundle if bundle in params" do
      post :schedule, params_with_bundle
      assert_redirected_to project_bundle_path(project, bundle)
    end
  end

  describe "destroy" do
    let (:updatable_feature) {Factory :feature, name: "before update", project_id: project.id}
    let (:not_updatable_feature) {Factory :feature, story_id: 1123, project_id: project.id}

    it "deletes a feature if it is updatable" do
      updatable_feature
      delete :destroy, project_id: project.to_param, id: updatable_feature.id

      Feature.find(updatable_feature.id).should be_nil
    end

    it "deletes a bundled feature if updatable" do
      bundle = Factory :bundle
      updatable_feature
      delete :destroy, project_id: project.to_param, id: updatable_feature.id, bundle_id: bundle.id

      Feature.find(updatable_feature.id).should be_nil
    end
    it "does not delete a bundled feature if not updatable" do
      bundle = Factory :bundle
      not_updatable_feature
      delete :destroy, project_id: project.to_param, id: not_updatable_feature.id, bundle_id: bundle.id

      Feature.find(not_updatable_feature.id).should_not be_nil
    end
    it "does not delete a feature if it is not updatable" do
      not_updatable_feature
      delete :destroy, project_id: project.to_param, id: not_updatable_feature.id

      Feature.find(not_updatable_feature.id).should_not be_nil
    end

    it "redirects after delete back to origin features page " do
      updatable_feature
      delete :destroy, project_id: project.to_param, id: updatable_feature.id
      assert_redirected_to project_path(project)
    end

    it "redirects after delete back to origin bundle page " do
      bundle = Factory :bundle
      updatable_feature
      delete :destroy, project_id: project.to_param, id: updatable_feature.id, redirect_to_bundle_id: bundle.to_param
      assert_redirected_to project_bundle_path(project, bundle)
    end

    it "deletes feature BSON in appropriate array depending on which column it's in on bundles page" do
      bundle = Factory :bundle
      feature = Factory :feature, bundle_ids: [bundle.id]
      bundle.ready_to_schedule_order = feature.id
      bundle.save
      delete :destroy, project_id: project.to_param, id: feature.id

      bundle.reload

      bundle.ready_to_schedule_order.should_not include feature.id
    end
  end

  describe "tracker_web_hook" do
    let (:feature) {Factory :feature, story_id: 1123}
    let (:params_with_name_and_lables) {{"activity"=>{"event_type"=>"story_update",
          "stories"=>[{"id"=>feature.story_id,"name"=>"hello tracker change again",
          "labels"=>"features,labels", "owned_by"=>"Dont Want", "requested_by"=>"Dont Want"}]}}}

    it "checks event type" do
      post :tracker_web_hook, params_with_name_and_lables
      feature.reload.name.should == "hello tracker change again"
    end

    it "changes labels string to array" do
      post :tracker_web_hook, params_with_name_and_lables
      feature.reload.labels.should == ["features","labels"]
    end

    it "story_update with no name or labels"do
      post :tracker_web_hook, {"activity"=>{"event_type"=>"story_update",
        "stories"=>[{"id"=>feature.story_id,"description"=> "this is"}]}}
      feature.reload.description.should == "this is"
    end
  end

  describe "pagination" do

    it "works and shows at most 10 rows per page" do
      30.times { Factory.create :feature, labels: ["red"], project_id: project.id }

      get :index, page: 1, project_id: project.id

      Feature.should respond_to :paginate

      assigns(:features).count.should eq(10)
    end
    it "should only show features for a single project" do
      feature1 = Factory :feature, project_id: project.id
      feature2 = Factory :feature, project_id: nil

      get :index, page: 1, project_id: project.id

      assigns(:features).should include feature1
      assigns(:features).should_not include feature2
    end
  end

end
