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
	--tag caching and masteries are loaded and updated in weapon.lua, and global scope.
	--if something goes shit skyward, a fallback is here.
	if not masteries then
		--this section shouldn't run unless someone is a fuckwit.
		require "/items/active/weapons/masteries.lua"
		masteries.fallback=true
		masteries.update(0)
		sb.logError("FU/items/active/weapons/ranged/gun.lua: Something overwrote /items/active/weapons/weapon.lua! Engaging fallback.")
	end

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

	-- ***************************************************
	--FR stuff
	-- ***************************************************
	-- *****************************************Passive Weapon Masteries and Item Tag Caching ***************************
	-- ******************************************************************************************************************
	-- only apply the following if the character has a Mastery trait. These are ONLY obtained from specific types of gear or loot.
	-- this section also primes the code for later blocks. all loading of mastery variables should be done here. this is also one of two places where item tag caching occurs.
	-- this is also a good place to put simple, nonconditional mastery bonuses.

	--tag caching and masteries are in weapon.lua, and global scope -khe
	if masteries and masteries.fallback then
		masteries.update(0)
	end

	-- ***************************************************
	-- END FR STUFF
	-- ***************************************************

	self.weapon:update(dt, fireMode, shiftHeld)
end


function uninit()
	cancelEffects(true)
	if self.helper then
		self.helper:clearPersistent()
	end
	self.weapon:uninit()
end

function cancelEffects(fullClear)
	status.clearPersistentEffects("multiplierbonus")
	status.clearPersistentEffects("dodgebonus")
	status.clearPersistentEffects("listenerBonus")
	status.clearPersistentEffects("listenerbonus")
	
	--deprecate
	status.clearPersistentEffects("masteryBonus")
	status.clearPersistentEffects("masterybonus")
	--end deprecate
	self.inflictedHitCounter = 0
end