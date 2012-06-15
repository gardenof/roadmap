class RoadmapBundles.Helper.Bundle
	estimates_total: (features) ->
		features.reduce ((init, current, index, array) ->
  		init + current.estimate
		), 0

	formatted_bundle_name: (bundle_name) ->
    right_format = bundle_name.toLowerCase()
    return right_format.replace(" ", "-")

  provide_status_tag_template: (identifier, urls, bundle, feature) ->
  	switch identifier
  	  when "bundled"
  	    JST["bundles/ready_to_schedule_status_tags"](urls: urls, bundle: bundle, feature: feature)
  	  when "unestimated"
  	  	JST["bundles/ready_to_estimate_status_tags"](urls: urls, bundle: bundle, feature: feature)
  	  when "need-discussion"
  	  	#body...
  	  else
  	  	""