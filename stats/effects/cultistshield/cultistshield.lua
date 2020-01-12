require "/scripts/status.lua"

function init()
	if animator then
		self.listener = damageListener("damageTaken", function()
			animator.setAnimationState("shield", "hit")
		end)
	end

	effect.addStatModifierGroup({
		{stat = "protection", amount = 100.0},
		{stat = "fireResistance", amount = 100.0},
		{stat = "iceResistance", amount = 100.0},
		{stat = "poisonResistance", amount = 100.0},
		{stat = "electricResistance", amount = 100.0},
		{stat = "physicalResistance", amount = 100.0},
		{stat = "radioactiveResistance", amount = 100.0},
		{stat = "shadowResistance", amount = 100.0},
		{stat = "akkimariacidResistance", amount = 100.0},
		{stat = "centensianenergyResistance", amount = 100.0},
		{stat = "cosmicResistance", amount = 100.0}
	})
end

function update(dt)
	if animator then self.listener:update() end
end
