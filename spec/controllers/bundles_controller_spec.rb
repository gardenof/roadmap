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

    it "sets attached_features" do
      get :show, show_params
      assigns(:attached_features).should == bundle.attached_features
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
end
