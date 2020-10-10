require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/FRHelper.lua"

function init()
    self.critChance = config.getParameter("critChance", 0)
    self.critBonus = config.getParameter("critBonus", 0)
	activeItem.setCursor("/cursors/reticle0.cursor")
	animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

	self.weapon = Weapon:new()

	self.weapon:addTransformationGroup("weapon", {0,0}, 0)

	local primaryAbility = getPrimaryAbility()
	self.weapon:addAbility(primaryAbility)

	local secondaryAttack = getAltAbility(self.weapon.elementalType)
	if secondaryAttack then
        self.weapon:addAbility(secondaryAttack)
	end
	--*************************************
	-- FU/FR ADDONS
    setupHelper(self, "staff-init")
    if self.helper then
        self.helper:loadWeaponScripts("staff-init")
        self.helper:runScripts("staff-init")
    end

    --**************************************
	self.weapon:init()
end


function update(dt, fireMode, shiftHeld)
	self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
	if self.helper then
        self.helper:clearPersistent()
    end
	self.weapon:uninit()
end
