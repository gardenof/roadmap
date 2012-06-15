class RoadmapBundles.Views.FeaturesNeedsDiscussion extends RoadmapBundles.Views.FeaturesMain
	render:(specified_features, bundle) ->      
    $(@el).html(@template(specified_features,
                          bundle, 
                          "need-discussion", 
                          'NEEDS DISCUSSION',
                          false))
    this