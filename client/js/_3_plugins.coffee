$.fn.serializeObject = ->
  o = {}
  a = this.serializeArray()
  $.each a, ->
    if o[@name] isnt undefined
      if not o[@name].push
        o[@name] = [o[@name]]
      o[@name].push @value or ''
    else o[@name] = @value or ''
  o