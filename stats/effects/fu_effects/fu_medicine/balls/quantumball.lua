require "/scripts/util.lua"

function init()
	range=config.getParameter("range",200)
end

function update(dt)
	if not deltaTime or deltaTime > 1.0 then
		deltaTime=0.0
		pulse()
	else
		deltaTime=deltaTime+dt
	end
end

function effectNonPlayersInRange(range,effect,duration)
	local buffer=util.mergeLists(world.npcQuery(entity.position(),range),world.monsterQuery(entity.position(),range))
	for _,id in pairs(buffer) do
		effectTarget(id,effect,duration)
	end
end

function effectPlayersInRange(range,effect,duration)
	local buffer=world.playerQuery(entity.position(),range)
	for _,id in pairs(buffer) do
		effectTarget(id,effect,duration)
	end
end

function effectSelf(effect,duration)
	effectTarget(entity.id(),effect,duration)
end

function effectTarget(id,effect,duration)
	world.sendEntityMessage(id,"applyStatusEffect",effect,duration,entity.id())
end

function pulse()
	effectNonPlayersInRange(range,"timefreezeNoVFX",effect.duration())
	effectNonPlayersInRange(range,"invulnerable",effect.duration())
	--effectNonPlayersInRange(range,"statusimmunity",effect.duration())
	
	effectPlayersInRange(range,"superdarkstatUnblockableHidden",effect.duration())
	effectPlayersInRange(range,"timefreezeNoVFX",effect.duration())
	effectPlayersInRange(range,"invulnerable",effect.duration())
	--effectPlayersInRange(range,"statusimmunity",effect.duration())
end