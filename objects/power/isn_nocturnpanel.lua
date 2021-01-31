require '/scripts/fupower.lua'

function init()
	self.powerLevel = config.getParameter("powerLevel",1)
	power.init()
end

function update(dt)
	storage.checkticks = (storage.checkticks or 0) + dt
	if storage.checkticks >= 10 then
		storage.checkticks = storage.checkticks - 10
		if isn_powerGenerationBlocked() then
			animator.setAnimationState("meter", "0")
			power.setPower(0)
			object.setAllOutputNodes(false)
		else
			local location = isn_getTruePosition()
			local light = getLight(location) or 0
			local genmult = 0

			if light <= 0.01 then
				genmult = 10
			elseif light <= 0.15 then
				genmult = 8
			elseif light <= 0.35 then
				genmult = 5
			elseif light <= 0.50 then
				genmult = 3
			end

			if world.liquidAt(location)then genmult = genmult * 0.05 end -- water significantly reduces the output

			local generated = self.powerLevel * genmult

			if genmult >= 8 then
				animator.setAnimationState("meter", "4")
			elseif genmult >= 5 then
				animator.setAnimationState("meter", "3")
			elseif genmult >= 3 then
				animator.setAnimationState("meter", "2")
			elseif genmult > 0 then
				animator.setAnimationState("meter", "1")
			else
				animator.setAnimationState("meter", "0")
			end
			power.setPower(generated)
			object.setAllOutputNodes(genmult>0)
		end
	end
	power.update(dt)
end

function getLight(location)
	local objects = world.objectQuery(entity.position(), 10)
	local lights = {}
	for i=1,#objects do
		local light = world.callScriptedEntity(objects[i],'object.getLightColor')
		if light and (light[1] > 0 or light[2] > 0 or light[3] > 0) then
			lights[objects[i]] = light
			world.callScriptedEntity(objects[i],'object.setLightColor',{light[1]/3,light[2]/3,light[3]/3})
		end
	end
	local light = math.min(world.lightLevel(location),1.0)
	for key,value in pairs(lights) do
		world.callScriptedEntity(key,'object.setLightColor',value)
	end
	return light
end

function isn_powerGenerationBlocked()
	-- Power generation does not occur if...
	--local location = isn_getTruePosition()
	--return world.underground(location) or world.lightLevel(location) < 0.2 or (world.timeOfDay() > 0.55 and world.type() ~= 'playerstation') --or world.type == 'unknown'
end

function isn_getTruePosition()
	storage.truepos = storage.truepos or {entity.position()[1] + math.random(2,3), entity.position()[2] + 1}
	return storage.truepos
end
