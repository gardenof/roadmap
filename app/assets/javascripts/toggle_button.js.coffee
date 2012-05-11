jQuery ->

  $('.bundled_toggle').click (e) ->
    e.preventDefault()
    $wrapping_column= $(this).parent().parent().parent().parent()
    bundled_column= $wrapping_column.find '.panel:nth-of-type(1)'

    bundled_column.toggle()

  $('.underestimated_toggle').click (e) ->
    e.preventDefault()
    $wrapping_column= $(this).parent().parent().parent().parent()
    underestimated_column = $wrapping_column.find '.panel:nth-of-type(2)'
    underestimated_column.toggle()

  $('.needs_discussion_toggle').click (e) ->
    e.preventDefault()
    $wrapping_column= $(this).parent().parent().parent().parent()
    needs_discussion_column= $wrapping_column.find '.panel:nth-of-type(3)'
    needs_discussion_column.toggle()