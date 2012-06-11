class RoadmapBundles.Routers.Features extends Backbone.Router

  routes:
    'projects/:project_id/bundles/:id': 'show'

  initialize: ->
    @collection = new RoadmapBundles.Collections.Features()
    @collection.fetch()

  show: (project_id, bundle_id) ->
    view = new RoadmapBundles.Views.FeaturesIndex(collection: @collection)
    $('#container_app').html(view.render().el)