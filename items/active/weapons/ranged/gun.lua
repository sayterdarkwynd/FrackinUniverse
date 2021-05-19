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

    calculateMasteries() --determine any active Masteries

    primaryItem = world.entityHandItem(entity.id(), "primary")  --check what they have in hand
    altItem = world.entityHandItem(entity.id(), "alt")
    if primaryTagCacheItem~=primaryItem then
        primaryTagCache=primaryItem and tagsToKeys(fetchTags(root.itemConfig(primaryItem))) or {}
        primaryTagCacheItem=primaryItem
    elseif not primaryItem then
        primaryTagCache={}
    end
    if altTagCacheItem~=altItem then
        altTagCache=altItem and tagsToKeys(fetchTags(root.itemConfig(altItem))) or {}
        altTagCacheItem=altItem
    elseif not altItem then
        altTagCache={}
    end

	self.weapon:init()

end

function calculateMasteries() -- doesn't work inside certain functions, such as Update
    self.ammoMastery = status.stat("ammoMastery")
    self.fireRateMastery = status.stat("fireRateBonus")
    self.plasmaMastery = 1 + status.stat("plasmaMastery")
    self.bioMastery = 1 + status.stat("bioMastery")
    self.energyMastery = 1 + status.stat("energyMastery")
    self.pistolMastery = 1 + status.stat("pistolMastery")
    self.machinePistolMastery = 1 + status.stat("machinePistolMastery")
    self.sniperRifleMastery = 1 + status.stat("sniperRifleMastery")
    self.assaultRifleMastery = 1 + status.stat("assaultRifleMastery")
    self.grenadeLauncherMastery = 1 + status.stat("grenadeLauncherMastery")
    self.rocketMastery = 1 + status.stat("rocketMastery")
    self.shotgunMastery = 1 + status.stat("shotgunMastery") 
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

    --cache tag data for use
    if primaryTagCacheItem~=primaryItem then
        primaryTagCache=primaryItem and tagsToKeys(fetchTags(root.itemConfig(primaryItem))) or {}
        primaryTagCacheItem=primaryItem
    elseif not primaryItem then
        primaryTagCache={}
    end
    if altTagCacheItem~=altItem then
        altTagCache=altItem and tagsToKeys(fetchTags(root.itemConfig(altItem))) or {}
        altTagCacheItem=altItem
    elseif not altItem then
        altTagCache={}
    end
    local hand=activeItem.hand()
    local masterybonus={}

    if primaryTagCache["pistol"] or altTagCache["pistol"] 
    or primaryTagCache["assaultrifle"] or altTagCache["assaultrifle"] 
    or primaryTagCache["machinepistol"] or altTagCache["machinepistolpistol"] 
    or primaryTagCache["sniperrifle"] or altTagCache["sniperrifle"] then  --magazine size
        self.ammoMastery = 1 + status.stat("ammoMastery")
        self.ammoMasteryThirded = ((self.ammoMastery -1) / 3) + 1
        status.setPersistentEffects("ammobonus", {
            {stat = "magazineSize", amount = 1 * self.ammoMastery},
            {stat = "reloadTime", amount = -self.ammoMasteryThirded}
        })         
    end
    --apply Gun mastery base parameters
    if primaryTagCache["pistol"] or altTagCache["pistol"] then  --reduced Reload time, increased magazine size, increased damage
        self.pistolMastery = 1 + status.stat("pistolMastery")
        self.pistolMasteryHalved = ((self.pistolMastery -1) / 2) + 1
        self.pistolMasteryThirded = ((self.pistolMastery -1) / 3) + 1
        self.pistolMasteryQuartered = ((self.pistolMastery -1) / 4) + 1
        status.setPersistentEffects("pistolbonus", {
            {stat = "powerMultiplier", effectiveMultiplier = 1 * self.pistolMasteryThirded},
            {stat = "critChance", amount = 1 * self.pistolMasteryHalved},
            {stat = "reloadTime", amount = -self.pistolMasteryQuartered}
        })         
    end
    if primaryTagCache["machinepistol"] or altTagCache["machinepistol"] then  --reduced power, Reload time, increased ammo count, crit chance
        self.machinePistolMastery = 1 + status.stat("machinePistolMastery")
        self.machinePistolMasteryHalved = ((self.machinePistolMastery -1) / 2) + 1
        self.machinePistolMasteryQuartered = ((self.machinePistolMastery -1) / 4) + 1
        status.setPersistentEffects("machinepistolbonus", {
            {stat = "powerMultiplier", effectiveMultiplier = 1 * self.machinePistolMasteryHalved},
            {stat = "reloadTime", amount = - self.machinePistolMasteryQuartered},
            {stat = "critChance", amount = 1 * self.machinePistolMasteryHalved}
        })         
    end
    if primaryTagCache["assaultrifle"] or altTagCache["assaultrifle"] then -- increased damage, magazine, crit damage
        self.assaultRifleMastery = 1 + status.stat("assaultRifleMastery")
        self.assaultRifleMasteryHalved = ((self.assaultRifleMastery -1) / 2) + 1
        self.assaultRifleMasteryThirded = ((self.assaultRifleMastery -1) / 3) + 1
        status.setPersistentEffects("assaultriflebonus", {
            {stat = "powerMultiplier", effectiveMultiplier = 1 * self.assaultRifleMasteryHalved},
            {stat = "magazineSize", amount = 1 * self.assaultRifleMasteryHalved},
            {stat = "critDamage", amount = 0.3 * self.assaultRifleMasteryHalved}
        })         
    end
    if primaryTagCache["sniperrifle"] or altTagCache["sniperrifle"] then -- increased magazine, crit chance
        self.sniperRifleMastery = 1 + status.stat("sniperRifleMastery")
        self.sniperRifleMasteryHalved = ((self.sniperRifleMastery -1) / 2) + 1
        self.sniperRifleMasteryQuartered = ((self.sniperRifleMastery -1) / 4) + 1
        status.setPersistentEffects("sniperriflebonus", {
            {stat = "critChance", amount = 1 * self.sniperRifleMasteryHalved},
            {stat = "magazineSize", amount = 1 * self.sniperRifleMasteryHalved}
        })         
    end
    if primaryTagCache["grenadelauncher"] or altTagCache["grenadelauncher"] then -- increased power, magazine size, reload time
        self.grenadeLauncherMastery = 1 + status.stat("grenadeLauncherMastery")
        self.grenadeLauncherMasteryHalved = ((self.grenadeLauncherMastery -1) / 2) + 1
        self.grenadeLauncherMasteryQuartered = ((self.grenadeLauncherMastery -1) / 2) + 1
        status.setPersistentEffects("grenadelauncherbonus", {
            {stat = "powerMultiplier", effectiveMultiplier = 1 * self.grenadeLauncherMasteryHalved},
            {stat = "reloadTime", amount = - self.grenadeLauncherMasteryQuartered},
            {stat = "magazineSize", amount = 1 * self.grenadeLauncherMasteryHalved}
        })         
    end
    if primaryTagCache["rocketlauncher"] or altTagCache["rocketlauncher"] then -- increased power, magazine size, reload time
        self.rocketLauncherMastery = 1 + status.stat("rocketLauncherMastery")
        self.rocketLauncherMasteryHalved = ((self.rocketLauncherMastery -1) / 2) + 1
        self.rocketLauncherMasteryQuartered = ((self.rocketLauncherMastery -1) / 4) + 1
        status.setPersistentEffects("rocketlauncherbonus", {
            {stat = "powerMultiplier", effectiveMultiplier = 1 * self.rocketLauncherMasteryHalved},
            {stat = "reloadTime", amount = - self.rocketLauncherMasteryQuartered},
            {stat = "magazineSize", amount = 1 * self.rocketLauncherMasteryHalved}
        })         
    end
    if primaryTagCache["shotgun"] or altTagCache["shotgun"] then  --increasd Power, Magazine Size, Crit Chance
        self.shotgunMastery = 1 + status.stat("shotgunMastery")
        self.shotgunMasteryHalved = ((self.shotgunMastery -1) / 2) + 1
        self.shotgunMasteryQuartered = ((self.shotgunMastery -1) / 4) + 1
        status.setPersistentEffects("shotgunbonus", {
            {stat = "powerMultiplier", effectiveMultiplier = 1 * self.shotgunMasteryHalved},
            {stat = "reloadTime", amount = - self.shotgunMasteryQuartered},
            {stat = "magazineSize", amount = 1 * self.shotgunMasteryHalved},
            {stat = "critChance", amount = 1 * self.shotgunMasteryQuartered}
        })         
    end    
    if primaryTagCache["energy"] or altTagCache["energy"] then  --increased Energy
        self.energyMastery = 1 + status.stat("energyMastery")
        self.energyMasteryHalved = ((self.energyMastery -1) / 2) + 1
        status.setPersistentEffects("energybonus", {
            {stat = "energyMax", effectiveMultiplier = 1 * self.energyMasteryHalved}
        })         
    end
    if primaryTagCache["plasma"] or altTagCache["plasma"] then  --increased Crit Damage
        self.plasmaMastery = 1 + status.stat("plasmaMastery")
        self.plasmaMasteryHalved = ((self.plasmaMastery -1) / 2) + 1
        status.setPersistentEffects("plasmabonus", {
            {stat = "critDamage", amount = 1 * self.plasmaMastery}
        })         
    end
    if primaryTagCache["bioweapon"] or altTagCache["bioweapon"] then  --increased Crit Chance
        self.bioWeaponMastery = 1 + status.stat("bioWeaponMastery")
        self.bioWeaponMasteryHalved = ((self.bioWeaponMastery -1) / 2) + 1
        status.setPersistentEffects("bioweaponbonus", {
            {stat = "critChance", amount = 1 * self.bioWeaponMasteryHalved}
        })         
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
    status.clearPersistentEffects("ammobonus")
    status.clearPersistentEffects("energybonus")
    status.clearPersistentEffects("plasmabonus")
    status.clearPersistentEffects("bioweaponbonus")
    status.clearPersistentEffects("pistolbonus")
    status.clearPersistentEffects("machinepistolbonus")
    status.clearPersistentEffects("assaultriflebonus")
    status.clearPersistentEffects("sniperriflebonus")
    status.clearPersistentEffects("grenadelauncherbonus")
    status.clearPersistentEffects("rocketlauncherbonus")
    status.clearPersistentEffects("shotgunbonus")
    status.clearPersistentEffects("multiplierbonus")
    status.clearPersistentEffects("dodgebonus")
    status.clearPersistentEffects("listenerBonus")
    status.clearPersistentEffects("listenerbonus")
    status.clearPersistentEffects("masteryBonus")
    status.clearPersistentEffects("masterybonus")
    self.inflictedHitCounter = 0
end


function fetchTags(iConf)
    if not iConf or not iConf.config then return {} end
    local tags={}
    for k,v in pairs(iConf.config or {}) do
        if string.lower(k)=="itemtags" then
            tags=util.mergeTable(tags,copy(v))
        end
    end
    for k,v in pairs(iConf.parameters or {}) do
        if string.lower(k)=="itemtags" then
            tags=util.mergeTable(tags,copy(v))
        end
    end
    return tags
end

function tagsToKeys(tags)
    local buffer={}
    for _,v in pairs(tags) do
        buffer[v]=true
    end
    return buffer
end
