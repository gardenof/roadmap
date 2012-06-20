class RoadmapBundles.Models.Feature extends Backbone.Model
	is_updatable: -> 
		!@get('story_id')?

	is_ready_for_estimate: ->
		!@get('estimate')? && @get('ready_for_estimate_at')?

	is_ready_to_schedule: ->
  	@get('estimate')? || !@is_updatable
	
	needs_discussion: ->
		!@is_ready_for_estimate() && !@is_ready_to_schedule()

	this.labels_formate= (labels) ->
    labels.replace(/\s/, '').split(",")
