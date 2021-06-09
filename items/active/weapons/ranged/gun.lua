require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/FRHelper.lua"

function init()
	--*************************************
	-- FU/FR ADDONS
	local species = status.statusProperty("fr_race") or world.entitySpecies(activeItem.ownerEntityId())

	if species then
		self.helper = FRHelper:new(species)
		self.helper:loadWeaponScripts("gun-init")
		self.helper:runScripts("gun-init", self)
	end
	status.setStatusProperty(activeItem.hand().."IsGun",true)
	--**************************************
	-- END FR BONUSES
	-- *************************************


	activeItem.setCursor("/cursors/reticle0.cursor")
	animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

	self.weapon = Weapon:new()

	self.weapon:addTransformationGroup("weapon", {0,0}, 0)
	self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

	local primaryAbility = getPrimaryAbility()
	self.weapon:addAbility(primaryAbility)

	local secondaryAbility = getAltAbility(self.weapon.elementalType)
	if secondaryAbility then
		self.weapon:addAbility(secondaryAbility)
	end

	self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
	self.weapon:update(dt, fireMode, shiftHeld)
end


function uninit()
	if self.helper then
		self.helper:clearPersistent()
	end
	status.setStatusProperty(activeItem.hand().."IsGun",nil)
	self.weapon:uninit()
end