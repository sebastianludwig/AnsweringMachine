$('.show-body').click(function(event) {
  $(this).closest('li').find('.response-body').toggle();
});

$('.response-body').hide();

$('.controls .btn-group .btn').click(function(event) {
  $('#http_status').attr('value', $(this).attr('value'));
});

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
