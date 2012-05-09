class Feature
  include MongoMapper::Document

  BugCost = 0.25
  ChoreCost = 0.25

  attr :tracker_errors

  key :accepted_at,           Time
  key :current_state,         String
  key :description,           String
  key :estimate,              Integer
  key :labels,                Array
  key :name,                  String, required: true
  key :owned_by,              String
  key :refreshed_at,          Time
  key :story_id,              Integer # Pivotal Tracker's ID
  key :story_type,            String


  key :project_id,            ObjectId
  belongs_to :project

  key :bundle_ids,            Array
  many :bundles, :in => :bundle_ids

  scope :with_label, -> label do
    where :labels => label
  end

  scope :accepted_in_period, -> period_start, period_end do
    where(:accepted_at.gte => period_start)
      .where(:accepted_at.lte => period_end)
  end

  scope :accepted_in_month, -> time do
    period_begin = time.beginning_of_month
    t1 = time.end_of_month
    period_end = Time.new(t1.year, t1.month, t1.day, 23, 59, 59)
    accepted_in_period(period_begin, period_end)
  end

  def tracker_errors
    @tracker_errors || []
  end

  def unchanged_after_refreshed
    if (changed? && refreshed_at_was.present? && !refreshed_at_changed?)
      errors.add(:base, "Can't update feature attributes after Tracker refresh")
    end
  end

  def updatable?
    !story_id?
  end

  def accepted?
    current_state.downcase == "accepted"
  end

  def cost
    case story_type
      when TrackerIntegration::StoryType::Bug then BugCost
      when TrackerIntegration::StoryType::Chore then ChoreCost
      else ( (estimate && (estimate > 0)) ? estimate : 0 )
    end
  end

  def update(story, refresh_time=Time.now)
    case story.class.to_s
    when 'PivotalTracker::Story'
      fill_from_field_list(
        story,
        TrackerIntegration::Story::StringFields) do |value|
          value
        end

      fill_from_field_list(
        story,
        TrackerIntegration::Story::ArrayFields) do |value|
          value.split ','
        end

      fill_from_field_list(
        story,
        TrackerIntegration::Story::NumericFields) do |value|
          value.to_i
        end

      fill_from_field_list(
        story,
        TrackerIntegration::Story::DateFields) do |value|
          value
        end

      self.refreshed_at = refresh_time
      self.story_id = story.id
    else
      super(story)
    end
    self
  end

  def create_in_tracker
    unless self.story_id.present?
      created_story = TrackerIntegration.create_feature_in_tracker(
        self.project.tracker_project_id, self
      )

      if created_story.errors.any?
        created_story.errors.each do |err|
          @tracker_errors = tracker_errors << err
        end
      end

      update(created_story)
    end
  end

  protected

  def fill_from_field_list(story, fieldlist)
    fieldlist.each do |field|
      value = story.send field
      if (value)
        self.send "#{field}=", yield(value)
      end
    end
  end

end
