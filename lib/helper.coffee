root = exports ? this

root.helper =
  angle: ( center , p1 ) ->
    p0 =
      x: center.x
      y: center.y - Math.sqrt( Math.abs(p1.x - center.x) * Math.abs(p1.x - center.x) + Math.abs(p1.y - center.y) * Math.abs(p1.y - center.y) )
      
    (2 * Math.atan2( p1.y - p0.y, p1.x - p0.x ) ) * 180 / Math.PI