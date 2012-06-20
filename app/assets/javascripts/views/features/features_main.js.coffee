class RoadmapBundles.Views.FeaturesMain 
  constructor: (project_name, bundle) ->
    @bundle = bundle
    @project = project_name
    @url_helper = new RoadmapBundles.Helper.Url()
    @bundle_helper = new RoadmapBundles.Helper.Bundle()
    @collection = new RoadmapBundles.Collections.Features(project_name)
    @collection.reset($('#bootstraped_features').data('features'))
    
    ready_for_schedule_view = new RoadmapBundles.Views.FeaturesReadyToSchedule(@collection, @url_helper, @bundle_helper, @bundle)
    ready_to_estimate_view = new RoadmapBundles.Views.FeaturesReadyToEstimate(@collection, @url_helper, @bundle_helper, @bundle)
    needs_discussion_view = new RoadmapBundles.Views.FeaturesNeedsDiscussion(@collection, @url_helper, @bundle_helper, @bundle)
    
    $('table.layout').find('tr').append(ready_for_schedule_view.render().el)
    $('table.layout').find('tr').append(ready_to_estimate_view.render().el)
    $('table.layout').find('tr').append(needs_discussion_view.render().el)