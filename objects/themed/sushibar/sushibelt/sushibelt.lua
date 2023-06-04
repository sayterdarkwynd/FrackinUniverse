function init()
local dir = object.direction()
object.smash(true)
world.placeObject("sushibeltcounterleft", entity.position(), dir)
world.placeObject("sushibeltcounterright", object.toAbsolutePosition({ 5.0, 0.0 }), dir)
world.placeObject("sushibeltconveyer", object.toAbsolutePosition({ 0.0, 2.0 }), dir)
end