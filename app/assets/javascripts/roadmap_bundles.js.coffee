window.RoadmapBundles =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  init: ->
    router = new RoadmapBundles.Routers.Features()
    Backbone.history.start(pushState: true)

$(document).ready ->
  RoadmapBundles.init()
