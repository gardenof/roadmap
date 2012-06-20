class RoadmapBundles.Views.FeaturesReadyToEstimate  extends Backbone.View
  tagName: "td"
  className: "panel unestimated"

  initialize: (collection, urls = '', bundle_helper = '', bundle = '') ->
    @url_helper = urls 
    @bundle_helper = bundle_helper 
    @bundle = bundle
    @collection = collection


  events:
    'click .feature-toggle' : 'expand_feature'

    
  expand_feature: (event)->
    $wrapping_div = $(event.target).parent().parent()
    $collapsed = $wrapping_div.find(".collapsed-feature")
    $expanded = $wrapping_div.find(".expanded-feature")
    $collapsed.toggle()
    $expanded.toggle()
    false


  template:(panel_class_name, title = "TITLE", show_total_estimates = false, has_status_tags = false) ->
   JST["features/index"](
    features: @collection.features_ready_for_estimate()  
    title: title
    total_estimates: if show_total_estimates is true then "(#{@bundle_helper.estimates_total(@collection.features_needing_discussion())}pts)" else "" 
    panel_class_name: panel_class_name
    urls: @url_helper
    bundle: @bundle
    bundle_helper: @bundle_helper
    has_status_tags: has_status_tags)

  render: ->      
    $(@el).html(@template("unestimated", 
                          'UNESTIMATED',
                          false,
                          true ))
    this