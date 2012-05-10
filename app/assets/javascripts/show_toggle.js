$(document).ready( function() {
  $('.feature-toggle').bind('click', function() {
    var $wrapping_div = $(this).parent().parent();
    var $collapsed = $wrapping_div.find ('.collapsed-feature');
    var $expanded = $wrapping_div.find ('.expanded-feature');

    $collapsed.toggle();
    $expanded.toggle();
    return false;
  })
});
