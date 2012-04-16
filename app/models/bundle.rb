class Bundle
  include MongoMapper::Document

  friendly_id :name

  key :name,          String,    required: true
  key :project_id,    ObjectId

  belongs_to :project

  def estimates_total
    estimated_features = Feature.where(bundle_ids: id).where(estimate: {:$gte => 0}).all
    estimated_features.inject(0) { |sum, f| sum += f.estimate }
  end

  def unestimated_count
    Feature.where(bundle_ids: self.id).where(estimate: nil).count
  end
end