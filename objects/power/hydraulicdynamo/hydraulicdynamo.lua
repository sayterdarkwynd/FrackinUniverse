require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fupower.lua"
require "/scripts/effectUtil.lua"
function init()
    power.init()
	transferUtil.init()
	object.setInteractive(true)
	powerStates = {
		{amount = 20, state = 'fast'},
		{amount = 12, state = 'fast'},
		{amount = 4, state = 'fast'},
		{amount = 0, state = 'off'}
	}
    self.fuels = config.getParameter("fuels")
	storage.active = true
	storage.active2 = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
end

function onInputNodeChange(args)
	onNodeConnectionChange(args)
end

function onNodeConnectionChange(args)
	storage.active2 = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
	power.onNodeConnectionChange(nil,0)
end

function update(dt)
	if not deltaTime or deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	if (not storage.active) or (not storage.active2) then
		animator.setAnimationState("screen", "off")
		power.setPower(0)
		power.update(dt)
		object.setAllOutputNodes(false)
		return
	end
	if storage.active2 then
		for i=0,2 do
			if isn_slotDecayCheck(i) then
			isn_doSlotDecay(i)
			isn_doSlotDecay(3)
			end
		end
	end
	local powerout = isn_getCurrentPowerOutput()
	power.setPower(powerout)
	for _,dink in pairs(powerStates) do
        if powerout >= dink.amount then
            animator.setAnimationState("screen", dink.state)
			animator.setAnimationRate(0.7 + 0.06*powerout)
            break
        end
	end
	object.setAllOutputNodes(powerout>0)
	power.update(dt)
end

function isn_powerSlotCheck(slotnum)
    local item = world.containerItemAt(entity.id(), slotnum)
    if not item then return 0 end
	return self and self.fuels and self.fuels[item.name] and self.fuels[item.name].power or 0
end

function isn_slotDecayCheck(slot)
	local item = world.containerItemAt(entity.id(),slot)
	local myLocation = entity.position()
    if item and isn_slotDecayCheckWater(3) and self and self.fuels and self.fuels[item.name] and math.random(1, self.fuels[item.name].decayRate) == 1 then
        return true
    end
	return false
end

function isn_slotDecayCheckWater(slot)
	local item = world.containerItemAt(entity.id(),slot)
	local myLocation = entity.position()
    if item and item.name == "liquidwater" then
        return true
    end
    if item and item.name == "fusaltwater" then
    	return true
    end
	return false
end

function isn_doSlotDecay(slot)
	world.containerConsumeAt(entity.id(),slot,1) --consume resource
end

function isn_getCurrentPowerOutput()
	local water = world.containerItemAt(entity.id(),3)
	if storage.active and water then
		local powercount = 0
		--local cooled=false
		if water.name == "liquidwater" or water.name == "fusaltwater" then
			for i=0,2 do
				powercount = powercount + isn_powerSlotCheck(i)
			end
			--cooled=true
			--object.say(powercount)
		end
		return powercount--,cooled
	else
		return 0,false
	end
end
