class RoadmapBundles.Views.FeaturesIndex extends Backbone.View
  tagName: "td"

  className: "bundled panel"

  initialize: ->
    @urls = new RoadmapBundles.Urls.BundleShow()


  render:(specified_features, bundle_id) ->
    form_template = JST["bundles/bundled_status_tags"]
  
    
    template = JST["features/index"](
  								features: specified_features
 									title: "BUNDLED"
  								panel_class_name: "bundled"
  								urls: @urls
 									bundle_id: bundle_id
 									feature_status_tags: form_template)
    $(@el).html(template)
    this


