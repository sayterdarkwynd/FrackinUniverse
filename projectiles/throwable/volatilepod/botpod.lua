require "/scripts/vec2.lua"

function init()
end

function update(dt)
	if mcontroller.isColliding() or vec2.mag(mcontroller.velocity()) < 0.1 then
		releaseMonsters()
	end
end

function hit(entityId)
    releaseMonsters()
end

function releaseMonsters()
	local damageTeam = entity.damageTeam()
	local entityId = world.spawnMonster(config.getParameter("monsterType","gleap"), mcontroller.position(), {
		level = config.getParameter("monsterLevel", 1),
		damageTeam = damageTeam.team,
		damageTeamType = damageTeam.type,
		aggressive = true
	})
	--[[local position = world.callScriptedEntity(entityId, "findGroundPosition", world.entityPosition(entityId), -10, 10, false)
	if position then
		world.callScriptedEntity(entityId, "mcontroller.setPosition", position)
	end]]
	projectile.die()
end
