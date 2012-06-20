class RoadmapBundles.Helper.Url
  project_feature_path: (feature_id) ->
    return "/projects/roadmap/features/" + feature_id

  move_feature_project_bundle_path: (feature_id, direction) ->
  	return "/projects/roadmap/bundles/test-bundle/move_feature?direction=#{direction}&amp;feature_id=#{feature_id}"

  remove_feature_project_bundle_path: (bundle_name) ->
  	return "/projects/roadmap/bundles/test-bundle/remove_feature"

  project_schedule_path: ->
  	 "/projects/roadmap/schedule"