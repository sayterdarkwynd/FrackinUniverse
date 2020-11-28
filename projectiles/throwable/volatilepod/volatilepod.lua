require "/scripts/poly.lua"
require "/scripts/companions/util.lua"

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
	local monsterType=config.getParameter("monsterType","gleap")
	local damageTeam = entity.damageTeam()
	local params=root.monsterParameters(monsterType)

	params.dropPools = {}
	params.dropPools["default"] = "empty"
	params.level = config.getParameter("monsterLevel", 1)
	params.damageTeam = damageTeam.team
	params.damageTeamType = damageTeam.type
	params.aggressive = true
	--params.persistent = true

	if params.statusSettings then
		if params.statusSettings.resources then
			params.statusSettings.resources.timeToLive={deltaValue=-1,initialValue=30}
		else
			projectile.die()
		end
	else
		projectile.die()
	end

	if params.behaviorConfig then
		if not params.behaviorConfig.spawnActions then
			params.behaviorConfig.spawnActions={}
		end
		table.insert(params.behaviorConfig.spawnActions,{parameters={duration=2,effect="volatilemonsterbomb"},name="action-statuseffect"})
	else
		projectile.die()
	end

	world.spawnMonster(monsterType, findCompanionSpawnPosition(mcontroller.position(),params.movementSettings.collisionPoly), params)
	projectile.die()
end
