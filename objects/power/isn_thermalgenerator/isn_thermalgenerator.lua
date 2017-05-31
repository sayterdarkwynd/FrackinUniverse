require "/objects/power/isn_sharedpowerscripts.lua"
require "/objects/isn_sharedobjectscripts.lua"

require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0
function init()
	transferUtil.init()
	object.setInteractive(true)
	object.setSoundEffectEnabled(false)
	
	storage.currentpowerprod = storage.currentpowerprod or 0
	storage.fueledticks = storage.fueledticks or 0
	storage.decayrate = storage.decayrate or 5
	if storage.active == nil then storage.active = true end
end

function onInputNodeChange(args)
	if object.isInputNodeConnected(0) then
		-- sb.logInfo("input node is connected. node level is %s", object.getInputNodeLevel(0))
		if object.getInputNodeLevel(0) then storage.active = true
		else storage.active = false
		end
	else storage.active = true
	end
end

function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end

	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	-- check current power production and set the animation state accordingly
	if storage.currentpowerprod > 90 then
		animator.setAnimationState("screen", "fast")
		object.setLightColor(config.getParameter("lightColor", {166, 166, 166}))
		object.setSoundEffectEnabled(true)
	elseif storage.currentpowerprod > 50 then
		animator.setAnimationState("screen", "med")
		animator.setAnimationState("fans", "fast")
		object.setLightColor(config.getParameter("lightColor", {100, 100, 100}))
		object.setSoundEffectEnabled(true)
	elseif storage.currentpowerprod > 10 then
		animator.setAnimationState("screen", "slow")
		animator.setAnimationState("fans", "slow")
		object.setLightColor(config.getParameter("lightColor", {50, 50, 50}))
		object.setSoundEffectEnabled(false)
	else
		animator.setAnimationState("screen", "off")
		animator.setAnimationState("fans", "off")
		object.setLightColor({0, 0, 0, 0})
		object.setSoundEffectEnabled(false)
	end

	if storage.fueledticks > 0 then -- if we're currently fueled up
		-- Decrement our current fuel by one
		storage.fueledticks = storage.fueledticks - 1
		-- Increase power but cap it at a 0-100 range
		storage.currentpowerprod = isn_numericRange((storage.currentpowerprod + storage.decayrate),0,100)
	else -- oh no we've got no fuel
		-- if the generator isn't active don't bother trying to refuel
		
		if storage.active == true then
			-- try to get some fuel
			local contents = world.containerItems(entity.id())
			if contents[1] == nil then
				-- if there's nothing in storage just skip straight to cutting power
				storage.currentpowerprod = isn_numericRange((storage.currentpowerprod - storage.decayrate),0,100)
				return
			end
			
			for key, value in pairs(config.getParameter("acceptablefuel")) do
				-- go through our fuel table and see if the contents of the fuel slot match
				if key == contents[1].name then -- found it!
					storage.fueledticks = value
					world.containerConsume(entity.id(), {name = contents[1].name, count = 1, data={}})
					return -- end it here since we want to start again with the new fuel
				end
			end
		end
		
		-- since the loop ends this update if it finds fuel, if we've reached this point
		-- it means we didn't find any fuel so now we decrease power gradually
		storage.currentpowerprod = isn_numericRange((storage.currentpowerprod - storage.decayrate),0,100)
	end
end

function isn_getCurrentPowerOutput(divide)
	---sb.logInfo("THERMAL GENERATOR CURRENT POWER OUTPUT DEBUG aka TGCPOD")
	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)
	---sb.logInfo("TGCPOD: Divisor is " .. divisor)
	if divisor < 1 then divisor = 1 end
	
	local powercount = 0
	if storage.currentpowerprod > 90 then powercount = 12
	elseif storage.currentpowerprod > 70 then powercount = 9
	elseif storage.currentpowerprod > 50 then powercount = 7
	elseif storage.currentpowerprod > 30 then powercount = 5
	elseif storage.currentpowerprod > 10 then powercount = 3	
	else powercount = 0 end
	---sb.logInfo("TGCPOD: Powercount is" .. powercount)
	
	---sb.logInfo("THERMAL GENERATOR CURRENT POWER OUTPUT DEBUG END")
	if divide then return powercount / divisor
	else return powercount end
end

function onNodeConnectionChange()
	if isn_checkValidOutput() then object.setOutputNodeLevel(0, true)
	else object.setOutputNodeLevel(0, false) end
end