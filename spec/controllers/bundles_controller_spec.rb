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

    it "should have order arrays populated with all its feature_ids" do
      feature_in_needing_discussion_column = Factory :feature, project_id: project.id, bundle_ids: [bundle.id], estimate: nil
      feature_in_schedule_column = Factory :feature, project_id: project.id, bundle_ids: [bundle.id]
      feature_in_estimate_column = Factory :feature, project_id: project.id, bundle_ids: [bundle.id], ready_for_estimate_at: Time.now, estimate: nil
      get :show, show_params
      bundle.reload
      bundle.needing_discussion_order.should_not == []
      bundle.ready_to_schedule_order.should_not == []
      bundle.ready_for_estimate_order.should_not == []
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



  describe "create_bundle_feature" do
    let(:project) {Factory :project}
    let(:bundle) {Factory :bundle, project_id: project.id}
    def create_bundle_feature_params(name = nil, label= "", description = "")
      { project_id: project.to_param,
        id: bundle.to_param,
        feature: {name: name, labels: label, description: description}
      }
    end


    it "creates a feature in a bundle and sets project_id, bundle_ids correctly" do
      post :create_bundle_feature, create_bundle_feature_params('hoho')
      feature_created=Feature.find_by_name('hoho')
      feature_created.should_not be_nil
      feature_created.project_id.class.should == BSON::ObjectId
      feature_created.bundle_ids[0].class.should == BSON::ObjectId
      response.should redirect_to project_bundle_path
    end


    it "should have a story_type after the feature is created" do
      post :create_bundle_feature, create_bundle_feature_params('story_type feature')
      feature_created = Feature.find_by_name('story_type feature')
      feature_created.story_type.should eq("feature")
    end

    it "doesn't create a feature for another project" do
      second_project = Factory :project
      project_one_bundle = bundle

      post :create_bundle_feature, {
        project_id: second_project.to_param,
        id: project_one_bundle.to_param,
        feature: {name: "don't create"}
      }

      Feature.find_by_name("don't create").should be_nil
    end

    it "sets lables to nil if none are past in params" do
      post :create_bundle_feature, create_bundle_feature_params('no lables')
      Feature.find_by_name("no lables").labels.should == []
    end

    it "saves lables correctly" do
      post :create_bundle_feature, create_bundle_feature_params("feature with lables", "one,     two")
      Feature.find_by_name("feature with lables").labels.should == ["one","two"]
    end

    it "should show form values even after a feature was unsuccessfully saved" do
      post :create_bundle_feature, create_bundle_feature_params(nil, "NoName", "I have no name" )
      bundle.reload
      assigns(:feature).description.should eq("I have no name")
    end

    it "does not redirect after validation failure" do
      post :create_bundle_feature, create_bundle_feature_params(nil,"NoName","I have no name" )
      bundle.reload
      response.should_not be_redirect
    end

    it "adds feature BSON to needs-discussion column after creating feature" do
      project_one_bundle = bundle
      post :create_bundle_feature, create_bundle_feature_params('generic feature')
      project_one_bundle.reload
      project_one_bundle.needing_discussion_order.should include assigns(:feature).id
    end
  end

  describe "move_feature" do
    let(:project) {Factory :project}
    let(:bundle) {Factory :bundle,
                 project_id: project.id,
                 ready_to_schedule_order: [],
                 ready_for_estimate_order: [],
                 needing_discussion_order: [] }

    let(:first_feature) {Factory :feature, bundle_ids: [bundle.id]}
    let(:second_feature) {Factory :feature, bundle_ids: [bundle.id]}


    def feature(est = nil, ready_time = nil)
      Factory :feature, {
      bundle_ids: [bundle.id],
      estimate: est,
      ready_for_estimate_at: ready_time
    }
    end

    def move_feature_params(direction, feature = first_feature)
      {
        project_id: project.to_param,
        id: bundle.to_param,
        feature_id: feature.to_param,
        direction: direction
      }
    end

    it "redirects" do
      bundle.ready_to_schedule_order = [first_feature.id]
      bundle.save
      post :move_feature, move_feature_params('up')
      response.should redirect_to project_bundle_path
    end

    it "moves the feature up for schedule column" do
      bundle.ready_to_schedule_order = [first_feature.id, second_feature.id]
      bundle.save
      post :move_feature, move_feature_params('up', second_feature)
      bundle.reload
      bundle.ready_to_schedule_order.should == [second_feature.id, first_feature.id]
    end

    it "moves the feature up for needs-discussion column" do
      needs_discussion_feature_a = feature
      needs_discussion_feature_b = feature
      bundle.needing_discussion_order = [needs_discussion_feature_a.id, needs_discussion_feature_b.id]
      bundle.save
      post :move_feature, move_feature_params('up', needs_discussion_feature_b)
      bundle.reload
      bundle.needing_discussion_order.should == [needs_discussion_feature_b.id, needs_discussion_feature_a.id]
    end

    it "moves the feature up for estimate column" do
      ready_for_estimate_feature_one = feature(nil, Time.now)
      ready_for_estimate_feature_two = feature(nil, Time.now)
      bundle.ready_for_estimate_order = [ready_for_estimate_feature_one.id, ready_for_estimate_feature_two.id]
      bundle.save
      post :move_feature, move_feature_params('up', ready_for_estimate_feature_two)
      bundle.reload
      bundle.ready_for_estimate_order.should == [ready_for_estimate_feature_two.id, ready_for_estimate_feature_one.id]
    end

    it "should not move up if feature at top for schedule column" do
      bundle.ready_to_schedule_order = [first_feature.id, second_feature.id]
      bundle.save
      post :move_feature, move_feature_params('up', second_feature)
      bundle.reload
      bundle.ready_to_schedule_order.should == [second_feature.id, first_feature.id]
    end

    it "it should raise error for bad feature" do
      bad_feature = Factory.build :feature
      bundle.ready_to_schedule_order = [first_feature.id]
      bundle.save
      lambda do
        post :move_feature, move_feature_params('up', bad_feature)
      end.should raise_error
    end

    it "should not move up if feature at top for estimate column" do
      ready_for_estimate_feature_one = feature(nil, Time.now)
      ready_for_estimate_feature_two = feature(nil, Time.now)
      bundle.ready_for_estimate_order = [ready_for_estimate_feature_one.id, ready_for_estimate_feature_two.id]
      bundle.save
      post :move_feature, move_feature_params('up', ready_for_estimate_feature_one)
      bundle.reload
      bundle.ready_for_estimate_order.should == [ready_for_estimate_feature_one.id, ready_for_estimate_feature_two.id]
    end

    it "should not move up if feature at top for needs-discussion column" do
      needs_discussion_feature_a = feature
      needs_discussion_feature_b = feature
      bundle.needing_discussion_order = [needs_discussion_feature_a.id, needs_discussion_feature_b.id]
      bundle.save
      post :move_feature, move_feature_params('up', needs_discussion_feature_a)
      bundle.reload
      bundle.needing_discussion_order.should == [needs_discussion_feature_a.id,  needs_discussion_feature_b.id]
    end
    it "moves the feature down for schedule column" do
      bundle.ready_to_schedule_order = [first_feature.id, second_feature.id]
      bundle.save
      post :move_feature, move_feature_params('down')
      bundle.reload
      bundle.ready_to_schedule_order.should == [second_feature.id, first_feature.id]
    end
    it "moves the feature down for estimate column" do
      ready_for_estimate_feature_one = feature(nil, Time.now)
      ready_for_estimate_feature_two = feature(nil, Time.now)
      bundle.ready_for_estimate_order = [ready_for_estimate_feature_one.id, ready_for_estimate_feature_two.id]
      bundle.save
      post :move_feature, move_feature_params('down', ready_for_estimate_feature_one )
      bundle.reload
      bundle.ready_for_estimate_order.should == [ready_for_estimate_feature_two.id,ready_for_estimate_feature_one.id]
    end
    it "moves the feature down for needs-discussion column" do
      needs_discussion_feature_a = feature
      needs_discussion_feature_b = feature
      bundle.needing_discussion_order = [needs_discussion_feature_a.id, needs_discussion_feature_b.id]
      bundle.save
      post :move_feature, move_feature_params('down', needs_discussion_feature_a)
      bundle.reload
      bundle.needing_discussion_order.should == [needs_discussion_feature_b.id, needs_discussion_feature_a.id]
    end

    it "should not move down if feature at bottom for schedule column" do
      bundle.ready_to_schedule_order = [first_feature.id, second_feature.id]
      bundle.save
      post :move_feature, move_feature_params('down', second_feature)
      bundle.reload
      bundle.ready_to_schedule_order.should == [first_feature.id, second_feature.id]
    end
    it "should not move down if feature at bottom for estimate column" do
      ready_for_estimate_feature_one = feature(nil, Time.now)
      ready_for_estimate_feature_two = feature(nil, Time.now)
      bundle.ready_for_estimate_order = [ready_for_estimate_feature_one.id, ready_for_estimate_feature_two.id]
      bundle.save
      post :move_feature, move_feature_params('down' , ready_for_estimate_feature_two)
      bundle.reload
      bundle.ready_for_estimate_order.should == [ready_for_estimate_feature_one.id, ready_for_estimate_feature_two.id]
    end
    it "should not move down if feature at bottom for needs-discussion column" do
      needs_discussion_feature_a = feature
      needs_discussion_feature_b = feature
      bundle.needing_discussion_order = [needs_discussion_feature_a.id, needs_discussion_feature_b.id]
      bundle.save
      post :move_feature, move_feature_params('down', needs_discussion_feature_b)
      bundle.reload
      bundle.needing_discussion_order.should == [needs_discussion_feature_a.id, needs_discussion_feature_b.id]
    end

    it "should raise error if the direction setting is not up or down" do
      lambda do
        post :move_feature, move_feature_params('left')
      end.should raise_error
    end
  end
end
