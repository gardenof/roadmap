class RoadmapBundles.Views.FeaturesMain extends Backbone.View
  tagName: "td"

  template:(specified_features, bundle, panel_class_name, title = "TITLE", show_total_estimates = false, has_status_tags = false) ->
   JST["features/index"](
    features: specified_features
    title: title
    total_estimates: if show_total_estimates is true then "(#{@bundle_helper.estimates_total(specified_features)}pts)" else "" 
    panel_class_name: panel_class_name
    urls: @url_helper
    bundle: bundle
    bundle_helper: @bundle_helper
    has_status_tags: has_status_tags
    formatted_bundle_name: @bundle_helper.formatted_bundle_name(bundle.name))


  initialize: ->
    @url_helper = new RoadmapBundles.Helper.Url()
    @bundle_helper = new RoadmapBundles.Helper.Bundle()