require "/stats/effects/medicalStationSpecials/medicalStatusBase.lua"

		-- "toxiccloudconfig":{
			-- "cloudInterval" : 3,
			-- "cloudDamage" : 5,
			-- "cloudDamageType" : "poison",
			-- "selfDamage" : 5,
			-- "selfDamageType" : "poison",
			-- "cloudDuration" : 5
		-- },

function init()
	if not toxSystemDidInit then
		toxInit()
	end
	if not medStationDidInit then
		medStationInit()
	end
end

function toxInit()
	if world.type() == "unknown" then
		self.onShip = true
	else
		self.toxiccloudconfig=config.getParameter("toxiccloudconfig")
	end

	if self.toxiccloudconfig then
		toxSystemDidInit=true
	else
		self.onShip=true
	end
end

function medStationInit()
	if self.toxiccloudconfig.useMedStationCode then
		baseInit()
		medStationDidInit=true
	end
end

function update(dt)
	if not toxSystemDidInit then
		toxInit()
	end
	if not medStationDidInit then
		medStationInit()
	end

	if not self.onShip then
		self.cloudTimer=(self.cloudTimer or 0)+dt
		if self.cloudTimer >= self.toxiccloudconfig.cloudInterval then
			status.applySelfDamageRequest({
				damageType = "IgnoresDef",
				damage = self.toxiccloudconfig.selfDamage,
				damageSourceKind = self.toxiccloudconfig.selfDamageType,
				sourceEntityId = entity.id()
			})

			world.spawnProjectile("medicaltoxiccloud", entity.position(), entity.id(), nil, nil, {
				power = self.toxiccloudconfig.cloudDamage * status.stat("powerMultiplier"),
				timeToLive = self.toxiccloudconfig.cloudDuration,
				damageKind = self.toxiccloudconfig.cloudDamageType
			})

			self.cloudTimer = 0
		end
	end

	if self.toxiccloudconfig.useMedStationCode then
		baseUpdate(dt)
	end
end

function uninit()
	--baseUninit(self.modifierGroupID)
end
