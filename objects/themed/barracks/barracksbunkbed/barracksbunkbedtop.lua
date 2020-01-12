function die()
local pos = object.toAbsolutePosition({ 0.0, -3.0 })
world.breakObject(tonumber(world.objectQuery(pos,pos)[1]),false)
end