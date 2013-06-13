root = exports ? this

root.helper =
  angle: ( center , p1 ) ->
    p0 =
      x: center.x
      y: center.y - Math.sqrt( Math.abs(p1.x - center.x) * Math.abs(p1.x - center.x) + Math.abs(p1.y - center.y) * Math.abs(p1.y - center.y) )
      
    (2 * Math.atan2( p1.y - p0.y, p1.x - p0.x ) ) * 180 / Math.PI

LocalCollection.Cursor::distinct = (key, random) ->
  self = this
  self.db_objects = self._getRawObjects(true)  if self.db_objects is null
  self.db_objects = _.shuffle(self.db_objects)  if random
  # if self.reactive
#     self._markAsReactive
#       ordered: true
#       added: true
#       removed: true
#       changed: true
#       moved: true

  res = {}
  _.each self.db_objects, (value) ->
    res[value[key]] = value  unless res[value[key]]

  _.values res