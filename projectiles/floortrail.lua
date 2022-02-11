require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
	local maximumHeight = config.getParameter("maximumHeight")
	local source 		= projectile.sourceEntity()
	local startPoint 	= world.entityPosition(source)
	local endPoint   	= vec2.add(startPoint, {0, -maximumHeight})
	local closeEnough 	= world.lineTileCollision(startPoint, endPoint, {"Null", "Block", "Dynamic", "Platform"})
	if not closeEnough then projectile.die() end

end
