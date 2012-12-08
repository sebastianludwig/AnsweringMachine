$('.show-body').click(function(event) {
  $(this).closest('li').find('.response-body').toggle();
});

$('.response-body').hide();

$.fn.getClassInList = function(list){
  for(var i = 0; i < list.length; i++) {
    if($(this).hasClass(list[i]))
      return list[i];
  }
  return "";
}

$('.delete,.put').click(function() {
  var form = $(document.createElement('form'));
  form.attr({
    method: 'post',
    action: $(this).attr('href')
  });
  form.css('display', 'none');
  form.append('<input type="hidden" name="_method" value="' 
    + $(this).getClassInList(['put', 'delete']).toUpperCase() 
    + '" />');
  $(this).after(form);
  
  form.submit();
  
  return false;
});
