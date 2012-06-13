class RoadmapBundles.Urls.BundleShow
  project_feature_path: (feature_id) ->
    return "/projects/roadmap/features/" + feature_id

  move_feature_project_bundle_path: (feature_id, direction) ->
  	return "/projects/roadmap/bundles/test-bundle/move_feature?direction=" + direction + "&feature_id=" + feature_id + " data-method='post' rel='nofollow' "
 	








