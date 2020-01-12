function init()
local dir = object.direction()
object.smash(true)
world.placeObject("picnictableleft", entity.position(), dir)
world.placeObject("picnictableright", object.toAbsolutePosition({ 3.0, 0.0 }), dir)
end