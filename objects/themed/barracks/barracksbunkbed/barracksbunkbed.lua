function init()
local dir = object.direction()
object.smash(true)
world.placeObject("barracksbunkbedbottom", entity.position(), dir)
world.placeObject("barracksbunkbedtop", object.toAbsolutePosition({ 0.0, 3.0 }), dir)
end