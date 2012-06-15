class RoadmapBundles.Views.FeaturesReadyForSchedule extends RoadmapBundles.Views.FeaturesMain
	className: "bundled panel"	

	render:(specified_features, bundle) ->      
    $(@el).html(@template(specified_features,
                          bundle, 
                          "bundled", 
                          'BUNDLED',
                          true),
    											true)
    this
