require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
	self.damageListener = damageListener("damageTaken",damageTaken)
	self.damageCounter=0
	script.setUpdateDelta(60)
end

function update(dt)
	self.damageListener:update()
	if self.damageCounter >= status.resourceMax("health") then
		trigger()
		self.damageCounter=0
	else
		self.damageCounter=self.damageCounter*(1-(dt*0.1))
	end
	--sb.logInfo("%s",self.damageCounter)
end

function damageTaken(notifications)
	for _, notification in pairs(notifications) do
		if notification.hitType == "Hit" then
			self.damageCounter=self.damageCounter+notification.damageDealt
		end
	end
end

function trigger()
	world.spawnMonster("fughostlostcat",entity.position())
end
