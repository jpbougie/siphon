var Siphon = {
  load: function(state) {
    $('#items').empty()
    $.getJSON('/load?state=' + state, 
      function(data) {
        $.each(data, function(i, item) {
          
          if($('#items li[rel=' + item.id + ']').length == 0) {
            $('#items').append($('<li></li>')
                                  .attr('rel', item.id)
                                  .data('value', item)
                                  .append(Siphon.format(item)))
          }
        })
        
        if(!(Siphon.focusedItem().length > 0)) {
          Siphon.focus(data[0].id)
        }
        
        Siphon.updateCount(state)
        $('.menu a').removeClass("highlight")
        $('.show_' + state).addClass("highlight")
        
        $('a[rel*=facebox]').facebox() 
        
      })
    
  },
  
  updateCount: function(state) {
    $('#count').text($('#items li').length)
    $('#' + state + '_count').text($('#items li').length)
  },
  
  bindKeys: function() {
    $('a.accept').live('click', function(a) { Siphon.accept() })
    $('a.reject').live('click', function(a) { Siphon.reject() })
    
    $(document).keypress(function(event) {
      switch(String.fromCharCode(event.which)) {
        case 'A':
        case 'a':
          Siphon.accept()
          break
        case 'r':
          Siphon.reject()
          break
        case 'j':
        case 'p':
          Siphon.previous()
          break
        case 'k':
        case 'n':
          Siphon.next()
          break
      }
    })
  },
  
  focusedItem: function() {
    return $('.focus')
  },
  
  focus: function(elemId) {
    if(Siphon.focusedItem().length > 0) {
      Siphon.unfocus()
    }
    
    elem = $('#items li[rel=' + elemId +']')
    
    if(elem.get()) {      
      elem.addClass('focus')
      elem.empty()
      elem.append(Siphon.formatFocused($(elem.get(0)).data('value')))
      $('a[rel*=facebox]', elem).facebox()
    }
  },
  
  unfocus: function() {
    elem = $('.focus')
    elem.removeClass('focus')
    elem.empty()
    elem.append(Siphon.format($(elem).data('value')))
    $('a[rel*=facebox]', elem).facebox()
  },
  
  format: function(item) {
    return  $('<span></span>').append(item.data)
                              .append($("<a>inspect</a>").attr("rel", "facebox")
                                                         .attr("href", "/couch/" + item.id))
  },
  
  formatFocused: function(item) {
    return $('<div></div>').addClass('focused')
                           .append($('<span></span>').addClass('subject').append(item.data))
                           .append($('<span></span>').addClass('state').append(item.state))
                           .append($('<a>source</a>').addClass('source').attr('href', item.source))
                           .append($('<div></div>').addClass('actions')
                                        .append($('<a href="#">accept</a>').addClass('accept'))
                                        .append($('<a href="#">reject</a>').addClass('reject'))
                                        .append($("<a>inspect</a>").attr("rel", "facebox")
                                                            .attr("href", "/couch/" + item.id)))
  },
  
  accept: function() {
    if(Siphon.focusedItem().length > 0) {
      Siphon.focusedItem().addClass("accepted")
      $.post('/accept', {id: Siphon.focusedItem().attr('rel')}, function(data) {
        elem = Siphon.focusedItem().next('li').attr('rel')
        Siphon.focusedItem().remove()
        Siphon.focus(elem)
        Siphon.refresh()
        Siphon.updateCount()
      })
    }
  },
  
  reject: function() {
    if(Siphon.focusedItem().length > 0) {
      $.post('/reject', {id: Siphon.focusedItem().attr('rel')}, function(data) {
        elem = Siphon.focusedItem().next('li').attr('rel')
        Siphon.focusedItem().remove()
        Siphon.focus(elem)
        Siphon.refresh()
        Siphon.updateCount()
      })
    }
  },
  
  refresh: function() {
    if($('#items li').length <= 10) {
      Siphon.load()
    }
  },
  
  skip: function() {
    
  },
  
  next: function() {
    if(Siphon.focusedItem() && Siphon.focusedItem().next('li').length > 0) {
      Siphon.focus(Siphon.focusedItem().next('li').attr('rel'))
    }
    else
    {
      Siphon.focus($('#items li:first').attr('rel'))
    }
  },
  
  previous: function() {
    if(Siphon.focusedItem() && Siphon.focusedItem().prev('li').length > 0) {
      Siphon.focus(Siphon.focusedItem().prev('li').attr('rel'))
    }
    else
    {
      Siphon.focus($('#items li:last').attr('rel'))
    }
  }
}