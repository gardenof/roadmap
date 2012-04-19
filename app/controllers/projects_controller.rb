class ProjectsController < ApplicationController
  include BilgePump::Controller
    before_filter :tracker_projects_not_in_roadmap, :only => [:index]

  def show
    @project = Project.find(params["id"])
    if @project == nil
      render :file => "#{Rails.root}/public/404.html", :status => :not_found
    end
  end

  protected
  def tracker_projects_not_in_roadmap 
    tracker_projects = PivotalTracker::Project.all
    roadmap_projects = Project.all

   @projects_not_in_roadmap = tracker_projects.reject do |tp|
      roadmap_projects.any? do |rmp|
        tp.id == rmp.tracker_project_id
      end
    end
  end
end