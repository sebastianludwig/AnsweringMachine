$('.tab-pane').on('click', '.show-body', function(event) {
  $(this).closest('li').find('.response-body').toggle();
});

$('.response-body').hide();
$('[rel=tooltip]').tooltip();
$('a.brand').popover({
  "html": true, 
  "title": function() {
    return '<span>Powered by <a href="http://www.lurado.com">Lurado</a></span>' +
          '<span class="version">v 0.8</span>'
  },
  "content": function() {
    return '<p>Check out the project page and documentation on <a href="https://github.com/sebastianludwig/AnsweringMachine" title="GitHub">GitHub</a>.</p>' +
          '<p><small>Developed by Sebastian Ludwig</small>.</p>'
  }
});

$('#match_received_data').click(function() {
    $('#received_data').toggleClass('hidden', !$(this).is(":checked"));
});

$('.http-method button').click(function() {
  var name = $(this).attr('name')
  var value = $(this).hasClass('active') ? "1" : "0"
  var checkbox = $('input[type=checkbox][name=' + name + ']')
  checkbox.prop('checked', !checkbox.is(":checked"))
});

$('.status-button').bind('activate', function(event, value) {
  $(this).closest('.http-status').find('.active').removeClass('active')
  $(this).toggleClass('active')
  $(this).text(value)
  $('#http-status').attr('value', value)
})

$('.status-button').click(function(event) {
  $(this).trigger('activate', $(this).text().trim())
})

$('.http-status .dropdown-menu li a').click(function(event) {
  // activate button
  $(this)
    .closest('.btn-group')
    .find('.status-button')
    .trigger('activate', $(this).text().trim())
  
  // select 
  var parent = $(this).closest('.http-status')
  
  parent && parent
    .find('.selected')
    .removeClass('selected')

  $(this).toggleClass('selected')
})

$('.http-status .dropdown-menu li > a').hover(
  function() {
    $(this).css('background', function(index, value) {
      return $(this).closest('.btn-group').find('.dropdown-button').css('background')
    })
  },
  function() {
    $(this).css('background', 'white')
  }
)

$('.nav-tabs li a').click(function() {
  $('.nav-tabs input').attr('value', $(this).data('value'))
});

$('.tab-pane').on('click', '.delete,.put', function(event) {
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

function removeHttpHeader(link) {
  $(link).closest('.http-header').remove()
}

$('[data-toggle="tabajax"]').click(function(e) {
    // http://jsfiddle.net/adrienne/La2765jn/
    var $this = $(this),
        loadurl = $this.attr('href'),
        targ = $this.attr('data-target');

    $.get(loadurl, function(data) {
        data = $(data);
        data.find('.response-body').hide();
        $(targ).html(data.html());
        $(targ).syntaxHighlight();
    });

    $this.tab('show');
    return false;
});
