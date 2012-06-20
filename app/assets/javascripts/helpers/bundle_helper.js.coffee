class RoadmapBundles.Helper.Bundle
	estimates_total: (features) ->
		features.reduce ((init, current, index, array) ->
      init + current.get('estimate')
		), 0


	formatted_bundle_name: (bundle_name) ->
    right_format = bundle_name.toLowerCase()
    return right_format.replace(" ", "-")

  status_tag_template: (identifier, urls, bundle, feature) ->
  	switch identifier
  	  when "bundled"
  	    JST["features/ready_to_schedule_status_tags"](urls: urls, bundle: bundle, feature: feature)
  	  when "unestimated"
  	  	JST["features/ready_to_estimate_status_tags"](urls: urls, bundle: bundle, feature: feature)
  	  when "need-discussion"
  	  	JST["features/needs_discussion_status_tags"](urls: urls, bundle: bundle, feature: feature)
  	  else
  	  	""

  simpleFormat: (str) ->
    str = str.replace(/\r\n?/, "\n")
    str = $.trim(str)
    if str.length > 0
      str = str.replace(/\n\n+/g, "</p><p>")
      str = str.replace(/\n/g, "<br />")
      str = "<p>" + str + "</p>"
    str