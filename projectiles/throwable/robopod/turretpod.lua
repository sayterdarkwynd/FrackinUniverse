require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
	monsterType = config.getParameter("monster")
	actionConfig = config.getParameter("actionConfig") or {}
	monsterLevelOffset = config.getParameter("monsterLevelOffset") or 0
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
	if done then return end
	local damageTeam = entity.damageTeam()
	-- local entityId =
	world.spawnMonster(monsterType, mcontroller.position(), {
		level = world.threatLevel() + monsterLevelOffset,
		damageTeam = damageTeam.team,
		damageTeamType = damageTeam.type,
		aggressive = true
	})
	--[[local position = world.callScriptedEntity(entityId, "findGroundPosition", world.entityPosition(entityId), -10, 10, false)
	if position then
		world.callScriptedEntity(entityId, "mcontroller.setPosition", position)
	end]]
	for _,action in pairs(actionConfig) do
		projectile.processAction(action)
	end
	done=true
	projectile.die()
end

--[[
	"actionOnReap": [{
			"action": "sound",
			"options": ["/sfx/tech/mech_activate4.ogg"]
		},
		{
			"time": 0.33,
			"action": "spawnmonster",
			"type": "futwigun2",
			"offset": [0, 0]
		},
		{
			"action": "projectile",
			"type": "electricexplosion",
			"inheritDamageFactor": 0.02,
			"config": {
				"speed": 0,
				"projectileParameters": {
					"periodicActions": []
				}
			},
			"fuzzAngle": 0,
			"angleAdjust": 0
		}
	]
]]

--[[
	"actionOnReap": [{
			"action": "sound",
			"options": ["/sfx/tech/mech_activate4.ogg"]
		},
		{
			"time": 0.33,
			"action": "spawnmonster",
			"type": "futrifangle",
			"offset": [0, 0]
		},
		{
			"action": "projectile",
			"type": "electricexplosion",
			"inheritDamageFactor": 0.02,
			"config": {
				"speed": 0,
				"projectileParameters": {
					"periodicActions": []
				}
			},
			"fuzzAngle": 0,
			"angleAdjust": 0
		}
	]
]]
