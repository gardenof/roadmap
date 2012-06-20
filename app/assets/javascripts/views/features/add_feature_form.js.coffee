class RoadmapBundles.Views.AddFeatureForm extends Backbone.View
	tagName: "form"

	attributes: { "accept-charset": "UTF-8", action: "", method: "post"}

	template: JST["features/create_bundled_feature_dropdown"]

	render: ->
		$(@el).html(@template())
		this