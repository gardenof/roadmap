class RoadmapBundles.Views.FeaturesNeedsDiscussion  extends Backbone.View
  className: "need-discussion panel"
  tagName: "td"


  initialize: (collection, urls = '', bundle_helper = '', bundle = '') ->
    @url_helper = urls 
    @bundle_helper = bundle_helper
    @bundle = bundle
    @collection = collection
    @collection.on('add', @render, this)
    @collection.reset

  events:
    'click .feature-toggle' : 'expand_feature'
    'click .new_form_dropdown input[type="submit"]': 'create_feature'
    'click .new_feature_toggle': 'show_form' 
    'mouseover .popup_btn' : 'show_hover'
    'mouseout .popup_btn'  : 'hide_hover'

  show_hover: (event) ->
    $feature = $(event.target).parent().find '.feature_name'
    
    $discription = $feature.attr "data-description"

    $popup_discription = $('<div id="popup_discription"></div>')
    $popup_discription.appendTo $(event.target).parent()

    $popup_discription.html $discription

  hide_hover: (event) ->
    $('div#popup_discription').remove()
    
  expand_feature: (event)->
    $wrapping_div = $(event.target).parent().parent()
    $collapsed = $wrapping_div.find(".collapsed-feature")
    $expanded = $wrapping_div.find(".expanded-feature")
    $collapsed.toggle()
    $expanded.toggle()
    false

  create_feature: (event) ->
    event.preventDefault()
    labels = if $('#feature_labels').val() == "" then else RoadmapBundles.Models.Feature.labels_formate($('#feature_labels').val())
    attributes = name: $('#feature_name').val(), labels: labels, description: $('#feature_description').val(), project_id: @bundle.project_id, bundle_ids: [@bundle.id]
    @collection.create attributes,
      wait: true

  appendEntry: (feature)->
    console.log @collection
    view = new RoadmapBundles.Views.FeaturesNeedsDiscussion(@collection, @url_helper, @bundle_helper, @bundle)
    @$('.need-discussion').html(view.render().el)

  get_or_create_form: ->
    if !@form_view?
      @form_view = new RoadmapBundles.Views.AddFeatureForm()
    @$('.new_form_dropdown').html(@form_view.render().el) 
    @form_view

  show_form: ->
    @get_or_create_form()
    $('.new_form_dropdown')
      .slideToggle('fast')

  template:(panel_class_name, title = "TITLE", show_total_estimates = false, has_status_tags = false) ->
   JST["features/index"](
    features: @collection.features_needing_discussion()  
    title: title
    total_estimates: if show_total_estimates is true then "(#{@bundle_helper.estimates_total(@collection.features_ready_for_estimate())}pts)" else "" 
    panel_class_name: panel_class_name
    urls: @url_helper
    bundle: @bundle
    bundle_helper: @bundle_helper
    has_status_tags: has_status_tags)


  render: ->      
    $(@el).html(@template("need-discussion", 
                          'NEEDS DISCUSSION',
                          false,
                          true))
    this