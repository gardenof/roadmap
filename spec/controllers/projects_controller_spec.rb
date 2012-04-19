require 'spec_helper'
describe ProjectsController do
  include BilgePump::Specs
  let (:tracker_project) {Factory.build(:pivotal_gem_tracker_project, id: 2000)}
  before do 
    PivotalTracker::Project.stub(:all).and_return([tracker_project])
  end

  def attributes_for_create
    { name: "Create NAME"}
  end

  def attributes_for_update
    { name: "Update NAME" }
  end
  describe "tracker_projects_not_in_roadmap" do 
    it "returns 200 OK" do
      project = Factory :project
      get :show, id: project.to_param
      response.should be_success
    end

    it "returns 404 not found" do
      get :show, id: "no project"
      response.should be_not_found
    end
  end

  describe "tracker_projects_not_in_roadmap" do 
    it "should return project" do
      project1= Factory :project, id: 1000
      get :index
      assigns(:projects_not_in_roadmap).should == [tracker_project]
    end
  end
end

