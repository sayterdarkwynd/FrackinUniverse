function init(virtual)
	if virtual == true then return end
end

function update(dt)
	if isn_hasRequiredPower() == false then
		entity.setAnimationState("switchState", "off")
		return
	end
	entity.setAnimationState("switchState", "on")
	
	--local targetlist = world.playerQuery(entity.position(),500)
	--for key, value in pairs(targetlist) do
	--	world.spawnProjectile("isn_atmosprojectile",world.entityPosition(value))
	--end
	isn_projectileAllInRange("isn_atmosprojectile",500)
end