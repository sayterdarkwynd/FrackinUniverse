require '/scripts/fupower.lua'

function init()
	self.powerLevel = config.getParameter("powerLevel",1)
	power.init()

	self.inSpace = world.getProperty("fu_byos.owner") or world.type() == 'playerstation' or world.type() == 'asteroids'
	local ePos=entity.position()
	storage.randomizedPos = storage.randomizedPos or {ePos[1] + math.random(2,3), ePos[2] + 1}
end

function update(dt)
	storage.checkticks = (storage.checkticks or 0) + dt
	if storage.checkticks >= 10 then
		storage.checkticks = storage.checkticks - 10
		if (world.underground(storage.randomizedPos) or ((not self.inSpace) and (world.timeOfDay() > 0.55))) then
			animator.setAnimationState("meter", "0")
			power.setPower(0)
			object.setAllOutputNodes(false)
		else
			getPowerLevel()
		end
	end
	power.update(dt)
end

function getPowerLevel()
	--local light = (world.type() ~= 'playerstation' and getLight(storage.randomizedPos) or 0.0)
	local light = getLight(storage.randomizedPos)
	local genmult = 1
	if self.inSpace then
		-- player space stations and ships always counts as high power, but never MAX power.
		genmult = 3.5
	elseif light >= 0.85 then
		genmult = 4 * (1 + light)
	elseif light >= 0.75 then
		genmult = 4
	elseif light >= 0.65 then
		genmult = 3
	elseif light >= 0.55 then
		genmult = 2
	elseif light <= 0.2 then
		genmult = 0
	end

	 -- water significantly reduces the output
	if world.liquidAt(storage.randomizedPos) then
		genmult = genmult * 0.05
	end

	local generated = self.powerLevel * genmult

	if genmult >= 4 or self.inSpace then
		animator.setAnimationState("meter", "4")
	elseif genmult >= 3 then
		animator.setAnimationState("meter", "3")
	elseif genmult >= 2 then
		animator.setAnimationState("meter", "2")
	elseif genmult > 0 then
		animator.setAnimationState("meter", "1")
	else
		animator.setAnimationState("meter", "0")
	end
	power.setPower(generated)
	object.setAllOutputNodes(generated>0)
end

function getLight(location)
	local objects = world.objectQuery(entity.position(), 20)
	local lights = {}
	for i=1,#objects do
		local light = world.callScriptedEntity(objects[i],'object.getLightColor')
		if light and (light[1] > 0 or light[2] > 0 or light[3] > 0) then
			lights[objects[i]] = light
			world.callScriptedEntity(objects[i],'object.setLightColor',{light[1]/3,light[2]/3,light[3]/3})
		end
	end

	 --via 'compressing' liquids like lava it is possible to get exhorbitant values on light level, over 100x the expected range.
	local light = math.min(world.lightLevel(location),1.0)
	for key,value in pairs(lights) do
		world.callScriptedEntity(key,'object.setLightColor',value)
	end
	return light
end
