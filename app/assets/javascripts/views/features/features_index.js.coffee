class RoadmapBundles.Views.FeaturesIndex extends Backbone.View
  tagName: "td"

  className: "bundled panel"

  initialize: ->
    @urls = new RoadmapBundles.Urls.BundleShow()


  render:(data) ->
    template = JST['features/index'](features: data, title: "BUNDLED", panel_class_name: 'bundled', urls: @urls )
    $(@el).html(template)
    this


