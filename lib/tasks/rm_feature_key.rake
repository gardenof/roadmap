task rm_feature_key: :environment do
  Feature.unset({}, :tracker_project_id)
end