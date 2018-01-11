
require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.cloudInterval = 0
	
	self.modifierGroupID = effect.addStatModifierGroup({
		{stat = "foodDelta", amount = config.getParameter("foodConsumption", 0)}
	})
	
	local data = root.assetJson("/projectiles/medicalStationSpecials/toxicCloud/toxiccloud.projectile")
	self.baseDamage = data.power
	
	baseInit()
end

function update(dt)
	if self.cloudInterval <= 0 then
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = config.getParameter("selfDamage", 0),
			damageSourceKind = config.getParameter("selfDamageType", 0),
			sourceEntityId = entity.id()
		})
		
		world.spawnProjectile("medicaltoxiccloud", entity.position(), entity.id(), nil, nil, {power = self.baseDamage * status.stat("powerMultiplier")})
		
		self.cloudInterval = config.getParameter("cloudInterval", 0)
	else
		self.cloudInterval = self.cloudInterval - dt
	end
	
	baseUpdate(dt)
end

function uninit()
	baseUninit(self.modifierGroupID)
end