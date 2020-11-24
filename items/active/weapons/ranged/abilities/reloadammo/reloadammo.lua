require "/scripts/util.lua"

ReloadAmmo = WeaponAbility:new()

function ReloadAmmo:init()
	self.cooldownTimer = 0
end

function ReloadAmmo:update(dt,fireMode,shiftHeld)
	WeaponAbility.update(self,dt,fireMode,shiftHeld)

	self.cooldownTimer = math.max(0,self.cooldownTimer-self.dt)

	if self.fireMode == "alt"
		and not self.weapon.CurrentAbility
		and self.cooldownTimer == 0
	then
		if self.weapon.reloadParam then --reloadParam is false for ejection and an array for energy reload
			if self.weapon.ammoAmount < self.weapon.ammoMax
				and not status.resourceLocked("energy")
			then
				if status.overConsumeResource("energy", self.weapon.reloadParam[2]) then
					self.weapon.ammoAmount = math.min(self.weapon.ammoMax,self.weapon.ammoAmount+self.weapon.reloadParam[1])
					activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
					animator.playSound("switchAmmo")
					animator.setAnimationState("gunState","reloading")
					self.cooldownTimer = self.weapon.reloadParam[3]
				end
			end
		else
			local extraStorage = config.getParameter("extraAmmoList") or {}
			local mag = config.getParameter("magazineType") or false
			local ammo = config.getParameter("ammoType")
			if self.weapon.ammoAmount > 0 then --don't know what will it do if told to spawn zero of something
				extraStorage[ammo] = self.weapon.ammoAmount + (extraStorage[ammo] or 0)
			end
			if mag and mag ~= "none" then
				extraStorage[mag] = 1 + (extraStorage[mag] or 0)
				activeItem.setInstanceValue("magazineType","none")
			end
			self.weapon.ammoAmount = 0
			activeItem.setInstanceValue("extraAmmoList",extraStorage)
			activeItem.setInstanceValue("extraAmmo",true)
			activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			animator.setAnimationState("gunState","reloading")
			activeItem.setInstanceValue("tooltipFields",{ammoNameLabel = "empty",ammoIconImage = ""})
			animator.playSound("switchAmmo")
			self.cooldownTimer = 1 --just how often do you need to unload it, mate?
		end
	end

end