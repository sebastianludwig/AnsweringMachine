$('.show-body').click(function(event) {
  $(this).closest('li').find('.response-body').toggle();
});

$('.response-body').hide();
$('[rel=tooltip]').tooltip();
$('[rel=popover]').popover();

$('.status_button').bind('activate', function(event, value) {
  $(this).closest('.http_status').find('.active').removeClass('active')
  $(this).toggleClass('active')
  $(this).text(value)
  $('#http_status').attr('value', value)
})

$('.status_button').click(function(event) {
  $(this).trigger('activate', $(this).text().trim())
})

$('.http_status .dropdown-menu li a').click(function(event) {
  $(this)
    .closest('.btn-group')
    .find('.status_button')
    .trigger('activate', $(this).text().trim())
})

$('.http_status .dropdown-menu li > a').hover(
  function() {
    $(this).css('background', function(index, value) {
      return $(this).closest('.btn-group').find('.dropdown_button').css('background')
    })
  },
  function() {
    $(this).css('background', 'white')
  }
)
  
$('.delete,.put').click(function() {
  var method = 'POST';
  if ($(this).hasClass('put')) {
    method = 'PUT';
  } else if ($(this).hasClass('delete')) {
    method = 'DELETE';
  }
  
  var form = $(document.createElement('form'));
  form.attr({
    method: 'post',
    action: $(this).attr('href')
  });
  form.css('display', 'none');
  form.append('<input type="hidden" name="_method" value="' + method + '" />');
  $(this).after(form);
  
  form.submit();
  
  return false;
});
