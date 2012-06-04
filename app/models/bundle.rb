class Bundle
  include MongoMapper::Document

  friendly_id :name

  key :name,                      String,    required: true
  key :project_id,                ObjectId
  key :positioned_feature_ids,    Array
  key :needing_discussion_order,  Array
  key :ready_for_estimate_order,  Array
  key :ready_to_schedule_order,   Array

  belongs_to :project

  def self.labels_formate(labels)
    labels.try(:gsub, /\s/, '').try(:split, ",")
  end

  def available_features
    Feature.where(:current_state => [nil, 'unstarted', 'unscheduled'], :project_id => project_id, :bundle_ids => { :$ne => id } ).order(:current_state.asc).all
  end

  def features
    @features ||= Feature.find_all_by_bundle_ids(id)
  end

  def features_needing_discussion
    features_needing_discussion=features.select { |f| f.needs_discussion? }
    populate_bundle_order_arrays(features_needing_discussion,self.needing_discussion_order)
    sort_features(features_needing_discussion, self.needing_discussion_order)
  end

  def features_ready_for_estimate
    features_ready_for_estimate=features.select { |f| f.ready_for_estimate? }
    populate_bundle_order_arrays(features_ready_for_estimate,self.ready_for_estimate_order)
    sort_features(features_ready_for_estimate, self.ready_for_estimate_order)
  end

  def features_ready_to_schedule
    features_ready_to_schedule = features.select { |f| f.ready_to_schedule? }
    populate_bundle_order_arrays(features_ready_to_schedule,self.ready_to_schedule_order)
    sort_features(features_ready_to_schedule, self.ready_to_schedule_order)
  end

  def populate_bundle_order_arrays(specified_features, order_array)
     if specified_features.count > order_array.count
        order_array.clear
        specified_features.each do |feature|
          order_array.push(feature.id)
        end
        self.save
    end
  end

  def sort_features(features_to_sort, order=[])
    sorted_features = []
    features_to_sort.each do |feature|
      index = order.index(feature.id)
      index == nil ? index = (sorted_features.count+50) : index
      sorted_features[index] = feature
    end
    sorted_features.compact
  end


  def estimates_total
    estimated_features = Feature.where(bundle_ids: id).where(estimate: {:$gte => 0}).all
    estimated_features.inject(0) { |sum, f| sum += f.estimate }
  end

  def unestimated_count
    Feature.where(bundle_ids: self.id).where(estimate: nil).count
  end
end