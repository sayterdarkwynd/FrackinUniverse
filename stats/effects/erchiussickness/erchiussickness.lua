require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.effectMaxErchius = config.getParameter("effectMaxErchius")
	self.effectDistance = config.getParameter("effectDistance")
	self.emissionRate = config.getParameter("emissionRate")
	self.desaturateAmount = config.getParameter("desaturateAmount")
	self.light = config.getParameter("lightColor")
	self.multiply = config.getParameter("multiplyColor")

	self.maxDps = config.getParameter("maxDps")
	self.damageDistance = config.getParameter("damageDistance")

	self.sapEnergy = config.getParameter("sapEnergy", false)
	self.spawnGhost = config.getParameter("spawnGhost", "erchiusghost")
	self.checkItems = config.getParameter("ghostItems", {"liquidfuel", "solidfuel", "supermatter"})
	self.messaged = config.getParameter("noRadioMessage", false)

	self.playerId = world.entityUniqueId(entity.id())
	if self.playerId then
		self.monsterUniqueId = string.format("%s-ghost", self.playerId)
	else
		self.monsterUniqueId = string.format("%s-ghost", sb.makeUuid())
	end
	self.findMonster = util.uniqueEntityTracker(self.monsterUniqueId, 0.2)
	self.saturation = 0
	self.dps = 0
	self.didSpawn = false

	self.spawnTimer = 0.5
end

function update(dt)
	local erchiusCount = 0
	for _,item in pairs(self.checkItems) do
		erchiusCount = erchiusCount + (world.entityHasCountOfItem(entity.id(), item) or 0)
	end
	local erchiusRatio = math.sqrt(math.min(1.0, erchiusCount / self.effectMaxErchius))
	if erchiusCount > 0 and self.spawnTimer > 0 then
		self.spawnTimer = self.spawnTimer - dt
	end

	if self.sapEnergy then
		if status.resource("energy") < 2 then
			status.modifyResource("health", ((-self.dps * dt)/12))
		end
		if self.dpsRatio and self.dpsRatio > 0.35 then
			status.setResourcePercentage("energyRegenBlock", 1.0)
		end
		status.modifyResource("energy", ((-self.dps * dt)*1.05))
	else
		status.modifyResource("health", -self.dps * dt)
	end

	local monsterPosition = self.findMonster()
	if monsterPosition then
		if not self.messaged and self.didSpawn then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "erchiussickness")
			self.messaged = true
		end

		local distance = world.distance(monsterPosition, mcontroller.position())
		animator.resetTransformationGroup("smoke")
		animator.rotateTransformationGroup("smoke", vec2.angle(distance))

		self.dpsRatio = 1 - math.min(1.0, math.max(0.0, vec2.mag(distance) / self.damageDistance))
		self.dps = self.dpsRatio * self.maxDps

		local effectDistance = interp.linear(erchiusRatio, self.effectDistance[1], self.effectDistance[2])
		local effectDistanceRatio = 1 - math.min(1.0, math.max(0.0, vec2.mag(distance) / effectDistance))
		animator.setParticleEmitterEmissionRate("smoke", self.emissionRate * effectDistanceRatio)
		animator.setParticleEmitterActive("smoke", effectDistanceRatio > 0)
		animator.setLightColor("glow", {self.light[1] * erchiusRatio, self.light[2] * erchiusRatio, self.light[3] * erchiusRatio})
		animator.setLightActive("glow", true)

		self.saturation = math.floor(-self.desaturateAmount * effectDistanceRatio)

		world.sendEntityMessage(self.monsterUniqueId, "setErchiusLevel", erchiusCount)
	elseif monsterPosition == nil then
		self.saturation = 0
		self.dps = 0
		animator.setLightActive("glow", false)
		animator.setParticleEmitterActive("smoke", false)

		if not self.playerId then
			self.playerId = world.entityUniqueId(entity.id())
			if self.playerId then
				self.monsterUniqueId = string.format("%s-ghost", self.playerId)
				self.findMonster = util.uniqueEntityTracker(self.monsterUniqueId, 0.2)
			end
		end
		if self.spawnTimer < 0 then
			local parameters = {
				level = world.threatLevel(),
				target = entity.id(),
				aggressive = true,
				uniqueId = self.monsterUniqueId,
				keepAlive = true
			}
			world.spawnMonster(self.spawnGhost, vec2.add(mcontroller.position(), config.getParameter("ghostSpawnOffset")), parameters)
			self.didSpawn = true
			self.spawnTimer = 1.0
		end
	end

	local multiply = {255 + self.multiply[1] * erchiusRatio, 255 + self.multiply[2] * erchiusRatio, 255 + self.multiply[3] * erchiusRatio}
	local multiplyHex = string.format("%s%s%s", toHex(multiply[1]), toHex(multiply[2]), toHex(multiply[3]))
	effect.setParentDirectives(string.format("?saturation=%d?multiply=%s", self.saturation, multiplyHex))
end

function toHex(num)
	local num2=math.floor(num + 0.5)
	local hex = string.format("%02X", num2)
	return hex
end

function uninit()
	-- no way to check if entity still exists
	if self.playerId then
		world.sendEntityMessage(self.monsterUniqueId, "setErchiusLevel", 0)
	else
		world.sendEntityMessage(self.monsterUniqueId, "killGhost")
	end
end
