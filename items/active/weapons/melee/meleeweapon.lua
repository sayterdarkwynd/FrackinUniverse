require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/FRHelper.lua"

function init()
	animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
	animator.setGlobalTag("directives", "")
	animator.setGlobalTag("bladeDirectives", "")

	self.weapon = Weapon:new()

	self.weapon:addTransformationGroup("weapon", {0,0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))
	self.weapon:addTransformationGroup("swoosh", {0,0}, math.pi/2)

	local primaryAbility = getPrimaryAbility()
	self.weapon:addAbility(primaryAbility)

	local secondaryAttack = getAltAbility()
	if secondaryAttack then
		self.weapon:addAbility(secondaryAttack)
	end

	self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
	-- ***************************************************
	--FR stuff
	-- ***************************************************
	setupHelper(self, "weapon-update")

	if self.helper then
		self.helper:runScripts("weapon-update", self, dt, fireMode, shiftHeld)
	end
	-- ***************************************************
	-- END FR STUFF
	-- ***************************************************

	self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
	if self.helper then
		self.helper:clearPersistent()
	end
	self.weapon:uninit()
end

function cancelEffects()
	status.clearPersistentEffects("longswordbonus")
	status.clearPersistentEffects("macebonus")
	status.clearPersistentEffects("katanabonus")
	status.clearPersistentEffects("rapierbonus")
	status.clearPersistentEffects("shortspearbonus")
	status.clearPersistentEffects("daggerbonus")
	status.clearPersistentEffects("scythebonus")
	status.clearPersistentEffects("axebonus")
	status.clearPersistentEffects("hammerbonus")
	status.clearPersistentEffects("multiplierbonus")
	status.clearPersistentEffects("dodgebonus")
	self.rapierTimerBonus = 0
end
