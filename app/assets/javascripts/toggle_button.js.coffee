jQuery ->

  $('.bundled_toggle').click (e) ->
    e.preventDefault()
    $wrapping_column= $('.layout')
    bundled_column= $wrapping_column.find '.bundled'

    bundled_column.toggle()

  $('.underestimated_toggle').click (e) ->
    e.preventDefault()
    $wrapping_column= $('.layout')
    underestimated_column = $wrapping_column.find '.unestimated'
    underestimated_column.toggle()

  $('.needs_discussion_toggle').click (e) ->
    e.preventDefault()
    $wrapping_column= $('.layout')
    needs_discussion_column= $wrapping_column.find '.need-discussion'
    needs_discussion_column.toggle()

  $('.new_feature_toggle').bind 'click', ->
    $('.new_form_dropdown').slideToggle('fast')

  $('#list').sortable
    axis: 'y'
    update: ->
      $.post($(this).data(''), $(this).sortable('serialize'))