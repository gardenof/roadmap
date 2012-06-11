class RoadmapBundles.Views.FeaturesIndex extends Backbone.View

  initialize: ->
    @collection.on('reset', @render, this)

  render: ->
    template = JST['features/index'](features: @collection)
    $(@el).html(template)
    this