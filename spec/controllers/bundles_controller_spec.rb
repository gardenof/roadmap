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

    it "sets available_features" do
      get :show, show_params
      assigns(:available_features).should == bundle.available_features
    end

    it "sets bundled_features" do
      get :show, show_params
      assigns(:bundled_features).should == bundle.features_ready_to_schedule
    end

    it "sets features_needing_discussion" do
      get :show, show_params
      assigns(:features_needing_discussion).should == bundle.features_needing_discussion
    end

    it "sets estimable_features" do
      get :show, show_params
      assigns(:estimable_features).should == bundle.features_ready_for_estimate
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

    it "returns successful message after successfully scheduling features" do
      feature = bundled_feature
      TrackerIntegration.stub(:create_feature_in_tracker).and_return(new_story)

      post :schedule, schedule_params

      flash[:notice].should == 'All features have successfully been loaded onto Pivotal Tracker'
    end

    it " returns failed message after failed attempt to schedule features" do
      feature = bundled_feature
      TrackerIntegration.stub(:create_feature_in_tracker).and_raise('poop')
      post :schedule, schedule_params

      flash[:error].should include "Caught exception from Tracker on feature #{feature.name}"
    end

    it "has no features in its bundle" do
      TrackerIntegration.should_not_receive(:create_feature_in_tracker)
      post :schedule, schedule_params
      flash[:error].should include "Please add features to the bundle before scheduling."
    end

    it "returns appropriate message if pivotal tracker refuses our create" do
      msgs = ['Name cannot be blank', 'Eat turds and perish']
      feature = bundled_feature

      Feature.any_instance.stub(:create_in_tracker)
      Feature.any_instance.stub(:tracker_errors).and_return(msgs)

      post :schedule, schedule_params

      flash[:error].should == msgs.join(',')
    end

  end

  describe "update_bundle_feature" do
    let (:project) { Factory :project}
    let (:bundle)  { Factory :bundle, project_id: project.id }
    let (:updatable_bundle_feature) {Factory :feature, story_id: nil, bundle_ids: [bundle.id], project_id: bundle.project.id}

    it "should redirect back to the bundle page" do
      put :update_bundle_feature, { project_id: bundle.project.to_param, id: bundle.to_param,
                              feature: { id: updatable_bundle_feature.id, description: updatable_bundle_feature.description }}
      response.should redirect_to project_bundle_path
    end

    it "updates the description only if it's updatable" do
      updatable_bundle_feature.should be_updatable
      put :update_bundle_feature, {
        project_id: bundle.project.to_param,
        id: bundle.to_param,
        feature: { id: updatable_bundle_feature.id, description: 'Wtf' }
      }

      updatable_bundle_feature.reload
      updatable_bundle_feature.description.should == "Wtf"
    end

    it "does not update the description  if it's not updatable and shows appropriate meesage" do
      non_updatable_bundle_feature = Factory :feature, story_id: 124345
      non_updatable_bundle_feature.should_not be_updatable
      put :update_bundle_feature, {
        project_id: bundle.project.to_param,
        id: bundle.to_param,
        feature: { id: non_updatable_bundle_feature.id, description: 'Wtf' }
      }

      non_updatable_bundle_feature.reload
      non_updatable_bundle_feature.description.should_not == "Wtf"
      flash[:notice].should eq("Can't update feature attributes after feature is in Tracker ")
    end
  end

  describe "create_bundle_feature" do
    it "creates a feature in a bundle and sets project_id, bundle_ids correctly" do
      project = Factory :project
      bundle = Factory :bundle, project_id: project.id

      post :create_bundle_feature, {
        project_id: project.to_param,
        id: bundle.to_param,
        feature: {name: 'hoho'}
      }

      feature_created=Feature.find_by_name('hoho')
      feature_created.should_not be_nil
      feature_created.project_id.class.should == BSON::ObjectId
      feature_created.bundle_ids[0].class.should == BSON::ObjectId
      response.should redirect_to project_bundle_path
    end

    it "doesnt create a feature for another project" do
      project_one = Factory :project
      project_one_bundle = Factory :bundle, project_id: project_one.id
      project_two = Factory :project

      post :create_bundle_feature, {
        project_id: project_two,
        id: project_one_bundle,
        feature: {name: "don't create"}
      }

      Feature.find_by_name("don't create").should be_nil
    end

    it "sets lables to nil if none are past in pramas" do
      project_one = Factory :project
      project_one_bundle = Factory :bundle, project_id: project_one.id

      post :create_bundle_feature, {
        project_id: project_one,
        id: project_one_bundle,
        feature: {name: "no lables"}
      }

      Feature.find_by_name("no lables").labels.should == []
    end

    it "saves lables correctly" do
      project_one = Factory :project
      project_one_bundle = Factory :bundle, project_id: project_one.id

      post :create_bundle_feature, {
        project_id: project_one,
        id: project_one_bundle,
        feature: {name: "feature with lables", labels: "one,    two"}
      }

      Feature.find_by_name("feature with lables").labels.should == ["one","two"]
    end
  end
end
