class RoadmapBundles.Collections.Features extends Backbone.Collection
 url: ->
 	"/projects/" + @project_name + "/features"
 model: RoadmapBundles.Models.Feature

 initialize: (project_name) ->
 	@project_name = project_name

 features_needing_discussion: ->
 	@models.filter (feature) ->
 		feature.needs_discussion()


 features_ready_for_estimate: ->
 	@models.filter (feature) ->
 		feature.is_ready_for_estimate()


 features_ready_to_schedule: ->
 	@models.filter (feature) ->
 		feature.is_ready_to_schedule()