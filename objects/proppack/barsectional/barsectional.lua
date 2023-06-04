function init()
local dir = object.direction()
object.smash(true)
world.placeObject("barsectionalleft", entity.position(), dir)
world.placeObject("barsectionalright", object.toAbsolutePosition({ 5.0, 0.0 }), dir)
end