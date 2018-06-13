function init()
	if world.type() ~= "unknown" then
		object.smash(false)
	end
	if not storage.watchBox then
		local myLocation = entity.position()
		storage.watchBox = {myLocation[1]-1, myLocation[2]-1, myLocation[1]+1, myLocation[2]+1}
	end
end

function update()
	world.loadRegion(storage.watchBox)
	if world.flyingType() == "warp" and world.warpPhase() == "maintain" then
		world.setProperty("fu_byos.inWarp", true)
	else
		world.setProperty("fu_byos.inWarp", false)
	end
end
