require "/scripts/util.lua"

fuStatusUtil={}
fuStatusUtil.vars={}

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	return math.floor(math.min(world.lightLevel(position),1.0) * 100)
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end

function nighttimeCheck()
	return world.timeOfDay() >= 0.5 -- true if night
end

function checkFood()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resource("food"))
end

function checkFoodPercent()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resourcePercentage("food"))
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function filterSpeed(speed,clear,override)
	if type(speed)~="number" then
		-- sb.logInfo("speed was somehow not number, it was instead %s",speed)
		speed=tonumber(speed)
	end
	if clear then
		legacySlow(statusUtilHandle())
		return
	end
	if status.statPositive("spikeSphereActive") then
		if not fuStatusUtil.vars.spikeState then
			legacySlow(statusUtilHandle())
			fuStatusUtil.vars.spikeState=true
		end
		fuStatusUtil.vars.speedModifier=1.0
		return 1.0
	else
		if (fuStatusUtil.vars.spikeState) or (fuStatusUtil.vars.speedModifier~=speed) then
			if speed<1.0 then
				legacySlow(statusUtilHandle(),speed)
			else
				legacySlow(statusUtilHandle())
			end
			fuStatusUtil.vars.speedModifier=speed
			fuStatusUtil.vars.spikeState=false
		end
		return speed
	end
end

function statusUtilHandle(fill)
	if not fuStatusUtil.vars.handle then
		fuStatusUtil.vars.handle=config.getParameter("statusUtilHandle") or fill or "generic"..(math.floor(math.random(0,1000000)*1000000))
	end
	return fuStatusUtil.vars.handle
end

--adds the stat modifier for AI pathing code
function filterAirJump(mod,clear)
	-- sb.logInfo("filterairjump %s",{m=mod,c=clear,paj=fuStatusUtil.vars.isPlayer_airJump})
	if not effect then return mod end
	if (not fuStatusUtil.vars.isPlayer_airJump) and world.entityType(entity.id())=="player" then
		fuStatusUtil.vars.isPlayer_airJump=true
		clear=true
	elseif (fuStatusUtil.vars.isPlayer_airJump) then
		return mod
	end

	if clear and fuStatusUtil.vars.airHandle then
		effect.removeStatModifierGroup(fuStatusUtil.vars.airHandle)
		fuStatusUtil.vars.airHandle=nil
		return
	end
	if not fuStatusUtil.vars.airHandle then
		fuStatusUtil.vars.airHandle=effect.addStatModifierGroup({})
	end
	effect.setStatModifierGroup(fuStatusUtil.vars.airHandle,{{stat="jumpModifier",amount=mod-1.0}})
	return mod
end

function applyFilteredModifiers(modifiers)
	mcontroller.controlModifiers(filterModifiers(modifiers))
end

function filterModifiers(stuff,clear)
	local moreStuff=copy(stuff)
	if clear then
		filterSpeed(0,true)
		filterAirJump(0,true)
		return
	end
	if moreStuff["speedModifier"] then
		moreStuff["speedModifier"]=filterSpeed(moreStuff["speedModifier"])
	end
	if moreStuff["airJumpModifier"] then
		moreStuff["airJumpModifier"]=filterAirJump(moreStuff["airJumpModifier"])
	end
	return moreStuff
end

--the below 2 functions are for legacy monster code, to handle their animation speeds. they don't actually slow anything.
function legacySlow(handle,modifier)
	if (not fuStatusUtil.vars.isPlayer_LegacySlow) and world.entityType(entity.id())=="player" then
		fuStatusUtil.vars.isPlayer_LegacySlow=true
		modifier=nil
	elseif fuStatusUtil.vars.isPlayer_LegacySlow then
		return
	end
	local slows = status.statusProperty("slows", {})
	if slows[handle]~=nil then
		slows[handle] = modifier
		status.setStatusProperty("slows", slows)
	end
end

function legacyStun(handle)
	local stuns = status.statusProperty("stuns", {})
	stuns[handle] = modifier
	status.setStatusProperty("stuns", stuns)
end
