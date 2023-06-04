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
	self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
	self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
	self.weapon:uninit()
end
