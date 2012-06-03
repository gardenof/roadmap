
path = location.pathname
split_path = path.split('/')
Dropdown =
  page_identifier: split_path[split_path.length - 1],

  show_form: ->
    if this.page_identifier == "create_bundle_feature"
      return true

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


  $dropdown_form = $('.new_feature_toggle')

  $dropdown_form.bind 'click', ->      
    $('.new_form_dropdown')
      .slideToggle('fast')

  if Dropdown.show_form
    $dropdown_form.trigger('click')


  $('#list').sortable
    axis: 'y'
    update: ->
      $.post($(this).data(''), $(this).sortable('serialize'))
