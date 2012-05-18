  # Place all the behaviors and hooks related to the matching controller here.
  # All this logic will automatically be available in application.js.

jQuery ->

  $('.popup_btn').hover (->

    $feature = $(this).parent().find '.feature_name'
    $discription = $feature.attr "data-description"

    $popup_discription = $('<div id="feature_description"></div>')
    $popup_discription.appendTo $(this).parent()

    $popup_discription.html $discription
  ), ->
    $('div#feature_description').remove()

