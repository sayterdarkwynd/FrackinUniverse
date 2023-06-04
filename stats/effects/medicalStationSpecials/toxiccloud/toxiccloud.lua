require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

function init()
	self.cloudInterval = 0
	self.baseCloudInterval = config.getParameter("cloudInterval", 0)
	self.onShip = false
	self.useMedStationCode=config.getParameter("useMedStationCode",true)
	self.damage=config.getParameter("selfDamage", 0)
	self.damageSourceKind=config.getParameter("selfDamageType", 0)

	local data = root.assetJson("/projectiles/medicalStationSpecials/toxicCloud/toxiccloud.projectile")
	self.baseDamage = data.power


	if world.type() == "unknown" then
		self.onShip = true
	end

	if self.useMedStationCode then
		baseInit()
	end
	didInit=true
end

function update(dt)
	if not didInit then
		init()
		return
	end

	if not self.onShip then
		if self.cloudInterval <= 0 then
			status.applySelfDamageRequest({
				damageType = "IgnoresDef",
				damage = self.damage,
				damageSourceKind = self.damageSourceKind,
				sourceEntityId = entity.id()
			})

			world.spawnProjectile("medicaltoxiccloud", entity.position(), entity.id(), nil, nil, {power = self.baseDamage * status.stat("powerMultiplier")})

			self.cloudInterval = self.baseCloudInterval
		else
			self.cloudInterval = self.cloudInterval - dt
		end
	end

	if self.useMedStationCode then
		baseUpdate(dt)
	end
end

function uninit()
	--baseUninit(self.modifierGroupID)
end