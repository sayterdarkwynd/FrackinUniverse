require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"
require("/scripts/FRHelper.lua")

Parry = WeaponAbility:new()

function Parry:init()
	species = status.statusProperty("fr_race") or world.entitySpecies(activeItem.ownerEntityId())
	self.cooldownTimer = 0
end

function Parry:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)

	self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

	if self.weapon.currentAbility == nil
		and fireMode == "alt"
		and self.cooldownTimer == 0
		and status.overConsumeResource("energy", self.energyUsage) then

		self:setState(self.parry)
	end
end

function Parry:parry()
	self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()

	status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})

	local blockPoly = animator.partPoly("parryShield", "shieldPoly")
	activeItem.setItemShieldPolys({blockPoly})

	animator.setAnimationState("parryShield", "active")
	animator.playSound("guard")

	local damageListener = damageListener("damageTaken", function(notifications)
		for _,notification in pairs(notifications) do
			if notification.sourceEntityId ~= activeItem.ownerEntityId() and notification.healthLost == 0 then

				if animator.hasSound("parry") then
					animator.playSound("parry")
				end
				animator.setAnimationState("parryShield", "block")
				if species == "hylotl" then
					--animator.burstParticleEmitter("bonusBlock")--cannot assume this is set.

					if animator.hasSound("bonusEffect") then
						animator.playSound("bonusEffect")
					elseif animator.hasSound("parry") then
						animator.playSound("parry")
					end
					self.blockCountShield = 0.008
					status.modifyResourcePercentage("health", 0.005 + self.blockCountShield )	--hylotl get a heal when they perfectly block
				end
				return
			end
		end
	end)

	util.wait(self.parryTime, function(dt)
		--Interrupt when running out of shield stamina
		if not status.resourcePositive("shieldStamina") then return true end

		damageListener:update()
	end)

	self.cooldownTimer = self.cooldownTime
	activeItem.setItemShieldPolys({})
end

function Parry:reset()
	animator.setAnimationState("parryShield", "inactive")
	status.clearPersistentEffects("broadswordParry")
	activeItem.setItemShieldPolys({})
end

function Parry:uninit()
	self:reset()
end
