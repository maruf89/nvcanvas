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

Handlebars.registerHelper "foreach", (arr, options) ->
  arr = arr.fetch()
  return options.inverse(this)  if options.inverse and not arr.length
  arr.map((item, index) ->
    item.$index = index
    item.$first = index is 0
    item.$last = index is arr.length - 1
    options.fn item
  ).join ""
