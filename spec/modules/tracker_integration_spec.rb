require 'spec_helper'

describe TrackerIntegration do

  describe "update_stories" do
    let (:tracker_story_one) { Factory.build :tracker_story}
    let (:tracker_story_two) { Factory.build :tracker_story}
    let (:feature1) { Factory :feature, name: "Old Value",
                                        story_id: tracker_story_one.id}
    let (:tracker_project) {Factory.build :pivotal_gem_tracker_project,
                                        name: "New Value"}
    # before(:each) {TrackerIntegration.stub(:iteration).and_return(
    #                             {})}

    it "has correct number of arguments" do
      PivotalTracker::Project.any_instance.stub(:stories).and_return(Project)
      PivotalTracker::Project.any_instance.stub(:iteration).and_return([])
      PivotalTracker::Project.stub(:find).and_return((Factory.build :pivotal_gem_tracker_project))

      TrackerIntegration.update_project(tracker_project.id)
    end
    before(:each) {TrackerIntegration.stub(:iteration).and_return(
                                {})}

    it "changes name of project" do
      project = Factory :project, tracker_project_id: tracker_project.id
      TrackerIntegration.update_stories([tracker_story_one],tracker_project)
      project.reload.name.should == tracker_project.name
    end

    it "updates features from stories" do
      feature1.name.should == "Old Value"
      TrackerIntegration.update_stories([tracker_story_one],tracker_project)
      feature1.reload.name.should == tracker_story_one.name
    end

    it "inserts features for new stories" do
      TrackerIntegration.update_stories([tracker_story_two],tracker_project)
      feature2 = Feature.find_by_story_id(tracker_story_two.id)
      feature2.name.should == tracker_story_two.name
    end

    it "save iteration to feature when current_state is unstarted" do
      feature = Factory :feature, story_id: tracker_story_one.id,
                                  current_state: "unstarted"
      feature.iteration.should == nil
      TrackerIntegration.stub(:iteration).and_return(
                                {"#{tracker_story_one.id}" => '2012-06-06 15:55:40 -0400',})
      TrackerIntegration.update_stories([tracker_story_one],tracker_project)

      feature.reload
      feature.iteration.should == '2012-06-06 15:55:40 -0400'
    end

    it "sets feature iteration to nil once current_state is no longer unstarted" do
      tracker_story_one.current_state = "accepted"
      feature = Factory :feature, story_id: tracker_story_one.id,
                                  current_state: "unstarted"
      TrackerIntegration.stub(:iteration).and_return(
                                {"#{tracker_story_one.id}" => Time.now})
      TrackerIntegration.update_stories([tracker_story_one],tracker_project)

      Feature.find_by_id(feature.id).iteration.should == "Mon Jun 02 12:03:15 -0700 2008"
    end
  end

  describe "check if tracker deleted" do
    let (:refresh_time) {Time.new(2012,2,03)}
    let (:tracker_story) {Factory.build :tracker_story}
    let (:project) {Factory :project,
                            :tracker_project_id => tracker_story.id}
    let (:feature) {Factory :feature,
                            :refreshed_at => Time.new(2009,1,03),
                            :project_id => project.id}
    it "sets type as deleted" do
      feature
      TrackerIntegration.mark_deleted_features(tracker_story,refresh_time)
      feature.reload
      feature.story_type.should == "Deleted"
    end

    it "don't sets type as deleted" do
      feature
      feature2 =Factory :feature,
                        :refreshed_at => refresh_time,
                        :project_id => project.id
      TrackerIntegration.mark_deleted_features(tracker_story,refresh_time)
      feature.reload
      feature2.story_type.should == "feature"
    end

    it "sets type as deleted" do
      feature
      TrackerIntegration.mark_deleted_features(tracker_story,refresh_time)
      feature.reload
      feature.story_id.should == nil
    end
  end


  describe "create_feature_in_tracker" do
    it "Gets project and feature ready to be created" do
      test_project_id = 477483

      feature = Factory :feature, story_id: nil

      some_fake_project = PivotalTracker::Project.new
      PivotalTracker::Project.stub(:find).and_return(some_fake_project)

      some_tracker_story = Factory.build :tracker_story
      TrackerIntegration.should_receive(:create_story_for_project).with(some_fake_project, feature).and_return(some_tracker_story)

      new_story = TrackerIntegration.create_feature_in_tracker(test_project_id, feature)

      new_story.should == some_tracker_story
    end

    it "creates a story in Tracker for a feature" do
      class ClassWithCreate
        def create(stuff)
        end
      end
      feature = Factory :feature, story_id: nil
      project = PivotalTracker::Project.new
      the_create_method = ClassWithCreate.new
      some_tracker_story = Factory.build :tracker_story


      project.should_receive(:stories).and_return(the_create_method)
      the_create_method.should_receive(:create).with(name: feature.name,
       estimate: feature.estimate, labels: feature.labels,
       description: feature.description).and_return(some_tracker_story)
      new_story = TrackerIntegration.create_story_for_project(project, feature)

      new_story.should == some_tracker_story
    end
  end
  describe "iteration" do

    it "should return a hash of just the feature_id and iteration date" do
      tracker_project = Factory.build :pivotal_gem_tracker_project
      project = Factory :project, tracker_project_id: tracker_project.id
      tracker_story_a = Factory.build :tracker_story
      tracker_story_b = Factory.build :tracker_story
      tracker_iteration =Factory.build :tracker_iteration, stories:[tracker_story_a,tracker_story_b]
      tracker_iteration_array = [tracker_iteration]

      feature_a = Factory :feature, story_id: tracker_story_a.id, project_id: project.id, iteration: nil
      feature_b = Factory :feature, story_id: tracker_story_b.id, project_id: project.id, iteration: nil

      hash_returned_from_iteration = {"#{tracker_story_a.id}" => tracker_iteration.start,
                                      "#{tracker_story_b.id}" => tracker_iteration.start}

      iteration_list = TrackerIntegration.iteration_hash(tracker_iteration_array)
      iteration_list.should == hash_returned_from_iteration
    end
  end
end