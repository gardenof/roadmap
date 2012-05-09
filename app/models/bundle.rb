class Bundle
  include MongoMapper::Document

  friendly_id :name

  key :name,          String,    required: true
  key :project_id,    ObjectId

  belongs_to :project

  def available_features
    Feature.where(:current_state => [nil, 'unstarted', 'unscheduled'], :project_id => project_id, :bundle_ids => { :$ne => id } ).order(:current_state.asc).all
  end

  def features
    Feature.find_all_by_bundle_ids(id)
  end

  def estimates_total
    estimated_features = Feature.where(bundle_ids: id).where(estimate: {:$gte => 0}).all
    estimated_features.inject(0) { |sum, f| sum += f.estimate }
  end

  def unestimated_count
    Feature.where(bundle_ids: self.id).where(estimate: nil).count
  end
end