module TrackerIntegration
  module Story
    StringFields = [
      # :attachments, 
      :current_state,
      :description,
      # :integration_id,
      # :jira_id,
      # :jira_url,
      :name,
      # :notes,
      # :other_id,
      # :owned_by,
      # :requested_by,
      # :story_type,
      # :taguri,
      # :url
    ]

    NumericFields = [
      :estimate,
      #:project_id
    ]

    ArrayFields = [
      :labels,
      # :tasks
    ]

    DateFields = [
      # :accepted_at,
      # :created_at
    ]
  end

  def self.update_project(token, tracker_project_id, project_id)
    PivotalTracker::Client.token = token
    tracker_project = PivotalTracker::Project.find(tracker_project_id)
    update_stories(tracker_project.stories.all, project_id)
  end

  def self.update_stories(stories, project_id)
    stories.each do |story|
      feature = Feature.find_by_story_id story.id
      feature ||= Feature.new
      feature.project_id = project_id
      feature.update(story).save
    end
  end

  def self.create_feature_in_tracker(token, tracker_project_id, feature)
    PivotalTracker::Client.token = token
    tracker_project = PivotalTracker::Project.find(tracker_project_id)
    create_story_for_project(tracker_project, feature)    
  end

  def self.create_story_for_project(tracker_project, feature)
    tracker_project.stories.create(name: feature.name, estimate: feature.estimate, labels: feature.labels, description: feature.description)
  end

end