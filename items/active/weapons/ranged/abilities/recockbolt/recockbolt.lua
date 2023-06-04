require "/scripts/util.lua"

RecockBolt = WeaponAbility:new()

function RecockBolt:init()
	self.cooldownTimer = 0
end

function RecockBolt:update(dt,fireMode,shiftHeld)
	WeaponAbility.update(self,dt,fireMode,shiftHeld)

	self.cooldownTimer = math.max(0,self.cooldownTimer-self.dt)

	if 	self.fireMode == "alt"
		and not self.weapon.CurrentAbility
		and self.cooldownTimer == 0
		and not self.weapon.cocked
	then
		self.weapon.cocked = true
		activeItem.setInstanceValue("cocked",true)
		if config.getParameter("cocked") then
			sb.logInfo ("cocked")
		else
			sb.logInfo ("fuck you")
		end
		animator.playSound("switchAmmo")
		animator.setAnimationState("gunState","reloading")
		if self.weapon.reloadParam then
			self.cooldownTimer = self.weapon.reloadParam[3]
		else
			self.cooldownTimer = 0.25
		end
	end

end