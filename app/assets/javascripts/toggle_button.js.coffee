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


  $('.new_bundle_feature').bind 'click', ->
    $('.show_my_ass').css 'z-index', '1000'
    $('.show_me').toggle()