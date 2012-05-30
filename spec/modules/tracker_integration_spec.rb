require 'spec_helper'

describe TrackerIntegration do

  describe "update_stories" do
    let (:story1) { Factory.build :tracker_story}
    let (:story2) { Factory.build :tracker_story}

    let (:feature1) { Factory :feature, name: "Old Value", story_id: story1.id}

    it "updates features from project" do
      TrackerIntegration.stub(:iteration)
      project = Factory :project, id: 1000, name: "Old Value"
      project2 = Factory.build :project, id: 1000,name: "New Value"
      project.name.should == "Old Value"
      TrackerIntegration.update_stories([story1],project2)
      project.reload.name.should == project2.name
    end

    it "updates features from stories" do
      TrackerIntegration.stub(:iteration)
      feature1.name.should == "Old Value"
      TrackerIntegration.update_stories([story1],story1)
      feature1.reload.name.should == story1.name
    end

    it "inserts features for new stories" do
      TrackerIntegration.stub(:iteration)
      feature2 = Feature.find_by_story_id(story2.id)
      feature2.should_not be_present

      TrackerIntegration.update_stories([story2],story2)

      feature2 = Feature.find_by_story_id(story2.id)
      feature2.should be_present
      feature2.name.should == story2.name
    end

    it "calls the iteration method after tracker update" do
      TrackerIntegration.should_receive(:iteration)
      project = Factory :project, id: 1000, name: "Old Value"
      TrackerIntegration.update_stories([story1], story1)
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

      iteration_list = TrackerIntegration.iteration_hash(tracker_iteration_array, tracker_project.id)
      iteration_list.should == hash_returned_from_iteration
    end


    it "should save iteration to feature" do
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

      iteration_list = TrackerIntegration.iteration_hash(tracker_iteration_array, tracker_project.id)

      feature_a.reload
      feature_a.iteration.should_not == nil
    end


  end
end