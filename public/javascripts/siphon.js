var Siphon = {
  load: function() {
    $.getJSON('/load', 
      function(data) {
        $.each(data, function(i, item) {
          $('#items').append($('<li></li>')
                                .attr('rel', item.id)
                                .data('value', item)
                                .append(Siphon.format(item)))
        })
        
        if(!(Siphon.focusedItem().length > 0)) {
          Siphon.focus(data[0].id)
        }
        
      })
    
  },
  
  bindKeys: function() {
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
    }
  },
  
  unfocus: function() {
    elem = $('.focus')
    elem.removeClass('focus')
    elem.empty()
    elem.append(Siphon.format($(elem).data('value')))
  },
  
  format: function(item) {
    return item.data
  },
  
  formatFocused: function(item) {
    return $('<div></div>').addClass('focused')
                           .append($('<span></span>').addClass('subject').append(item.data))
                           .append($('<span></span>').addClass('state').append(item.state))
                           .append($('<div></div>').addClass('actions')
                                        .append($('<a>accept</a>').addClass('accept'))
                                        .append($('<a>reject</a>').addClass('reject')))
  },
  
  accept: function() {
    if(Siphon.focusedItem().length > 0) {
      Siphon.focusedItem().addClass("accepted")
      $.post('/accept', {id: Siphon.focusedItem().attr('rel')}, function(data) {
        elem = Siphon.focusedItem().next('li').attr('rel')
        Siphon.focusedItem().remove()
        Siphon.focus(elem)
      })
    }
  },
  
  reject: function() {
    if(Siphon.focusedItem().length > 0) {
      $.post('/reject', {id: Siphon.focusedItem().attr('rel')}, function(data) {
        elem = Siphon.focusedItem().next('li').attr('rel')
        Siphon.focusedItem().remove()
        Siphon.focus(elem)
      })
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