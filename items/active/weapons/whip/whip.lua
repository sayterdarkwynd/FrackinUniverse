require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"
require("/scripts/FRHelper.lua")

function init()
    self.critChance = config.getParameter("critChance", 0)
    self.critBonus = config.getParameter("critBonus", 0)
	activeItem.setCursor("/cursors/reticle0.cursor")

	self.weapon = Weapon:new()

	self.weapon:addTransformationGroup("weapon", {0,0}, 0)

	self.primaryAbility = getPrimaryAbility()
	self.weapon:addAbility(self.primaryAbility)

	self.altAbility = getAltAbility()
	if self.altAbility then
        self.weapon:addAbility(self.altAbility)
	end

    self.whipMastery = 1 + status.stat("whipMastery")
    self.whipMasteryHalved = ((self.whipMastery -1) / 2) + 1
    self.whipMasteryThirded = ((self.whipMastery -1) / 3) + 1
    self.whipMasteryQuartered = ((self.whipMastery -1) / 4) + 1

	self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
    self.whipMastery = 1 + status.stat("whipMastery")
    self.whipMasteryHalved = ((self.whipMastery -1) / 2) + 1
    self.whipMasteryThirded = ((self.whipMastery -1) / 3) + 1
    self.whipMasteryQuartered = ((self.whipMastery -1) / 4) + 1
    self.whipMasteryTiny = ((self.whipMastery -1) / 48) + 1
    
    if self.whipMastery > 1 then
	    status.setPersistentEffects("whipbonus", {
	        {stat = "powerMultiplier", effectiveMultiplier = 1 * self.whipMastery},
	        {stat = "critChance", amount = 1 * self.whipMastery},
	        {stat = "critDamage", amount = 0.25 * self.whipMasteryHalved}
	    }) 
	    mcontroller.controlModifiers({speedModifier = 1 * self.whipMasteryHalved})
    end

	self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
	status.clearPersistentEffects("whipbonus")
	self.weapon:uninit()
end
