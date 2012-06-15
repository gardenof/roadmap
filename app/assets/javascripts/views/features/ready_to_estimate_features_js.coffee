class RoadmapBundles.Views.FeaturesReadyToEstimate extends RoadmapBundles.Views.FeaturesMain
	className: "panel unestimated"

	render:(specified_features, bundle) ->      
    $(@el).html(@template(specified_features,
                          bundle, 
                          "unestimated", 
                          'UNESTIMATED',
                          false,
                          true))
    this
