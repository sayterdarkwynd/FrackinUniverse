require "/items/active/tagCaching.lua"

masteries={}

function masteries.apply()
	--originally all masteries except fire rate were 1-centric. will need to adjust.
	local hand=activeItem.hand()

	--bonuses to ammo and reload time for weapons that tend to be ammo based.
	if tagCaching.mergedCache["machinepistol"]
	or tagCaching.mergedCache["assaultrifle"]
	or tagCaching.mergedCache["pistol"]
	or tagCaching.mergedCache["sniperrifle"] then
		status.setPersistentEffects("ammobonus", {
			{stat = "magazineMultiplier", effectiveMultiplier = 1 + masteries.stats.ammoMastery},
			{stat = "magazineSize", amount = 4 * masteries.stats.ammoMastery},
			{stat = "reloadTime", amount = -1/3 * masteries.stats.ammoMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","ammobonus")
	end

	--pistols: reduced Reload time, increased crit chance and damage
	if tagCaching.mergedCache["pistol"] then
		status.setPersistentEffects("pistolbonus", {
			{stat = "powerMultiplier", effectiveMultiplier = 1 + masteries.stats.pistolMastery},
			{stat = "critChance", amount = 1/4 * masteries.stats.pistolMastery},
			{stat = "reloadTime", amount = -1/4 * masteries.stats.pistolMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","pistolbonus")
	end

	--machine pistols: increased power & crit chance. reduced Reload time.
	if tagCaching.mergedCache["machinepistol"] then
		status.setPersistentEffects("machinepistolbonus", {
			{stat = "powerMultiplier", effectiveMultiplier = 1 + (masteries.stats.machinepistolMastery/2)},
			{stat = "reloadTime", amount = -1/4 * masteries.stats.machinepistolMastery},
			{stat = "critChance", amount = 1/2 * masteries.stats.machinepistolMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","machinepistolbonus")
	end

	--arm cannons: increased damage, defense. increased crit damage or crit chance.
	--values based on whether the person has either two arm cannons, a single one, or one with a shield.
	if tagCaching.mergedCache["armcannon"] then
		if tagCaching.primaryTagCache["armcannon"] and tagCaching.altTagCache["armcannon"] then
			--they have two armcannons active
			status.setPersistentEffects("armcannonbonus", {
				{stat = "powerMultiplier", effectiveMultiplier = 1 + masteries.stats.armcannonMastery},
				{stat = "protection", effectiveMultiplier = 1 + (masteries.stats.armcannonMastery/2)},
				{stat = "critChance", amount = 2 * masteries.stats.armcannonMastery}
			})
		elseif tagCaching.mergedCache["shield"] then
			--they have a shield active
			status.setPersistentEffects("armcannonbonus", {
				{stat = "powerMultiplier", effectiveMultiplier = 1 + (masteries.stats.armcannonMastery/3)},
				{stat = "protection", effectiveMultiplier = 1 + (masteries.stats.armcannonMastery)},
				{stat = "critDamage", amount = 0.3 * masteries.stats.armcannonMastery}
			})
		else
			status.setPersistentEffects("armcannonbonus", {
				{stat = "powerMultiplier", effectiveMultiplier = 1 + (masteries.stats.armcannonMastery/2)},
				{stat = "protection", effectiveMultiplier = 1 + (masteries.stats.armcannonMastery/2)},
				{stat = "critDamage", amount = 0.3 * masteries.stats.armcannonMastery}
			})
		end
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","armcannonbonus")
	end

	--assault rifles: increased damage, magazine, crit damage
	if tagCaching.mergedCache["assaultrifle"] then
		status.setPersistentEffects("assaultriflebonus", {
			{stat = "powerMultiplier", effectiveMultiplier = 1 + (masteries.stats.assaultrifleMastery/2)},
			--{stat = "magazineMultiplier", effectiveMultiplier = 1 + (masteries.stats.assaultrifleMastery/2)},
			--{stat = "magazineSize", amount = 2 * masteries.stats.assaultrifleMastery},
			{stat = "magazineSize", amount = 1/2 * masteries.stats.assaultrifleMastery},
			{stat = "critDamage", amount = 0.3/2 * masteries.stats.assaultrifleMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","assaultriflebonus")
	end

	--sniper rifles: increased magazine, crit chance
	if tagCaching.mergedCache["sniperrifle"] then
		status.setPersistentEffects("sniperriflebonus", {
			{stat = "critChance", amount = 1/2 * masteries.stats.sniperrifleMastery},
			--{stat = "magazineMultiplier", effectiveMultiplier = 1 + (masteries.stats.sniperrifleMastery/2)},
			--{stat = "magazineSize", amount = 2 * masteries.stats.sniperrifleMastery}
			{stat = "magazineSize", amount = 1/2 * masteries.stats.sniperrifleMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","sniperriflebonus")
	end

	--grenade launchers: increased power, magazine size. reduced reload time
	if tagCaching.mergedCache["grenadelauncher"] then
		status.setPersistentEffects("grenadelauncherbonus", {
			{stat = "powerMultiplier", effectiveMultiplier = 1 + (masteries.stats.grenadeLauncherMastery/2)},
			{stat = "reloadTime", amount = -1/4 * masteries.stats.grenadeLauncherMastery},
			--{stat = "magazineMultiplier", effectiveMultiplier = 1 + (masteries.stats.grenadeLauncherMastery/2)},
			--{stat = "magazineSize", amount = 2 * masteries.stats.grenadeLauncherMastery}
			{stat = "magazineSize", amount = 1/2 * masteries.stats.grenadeLauncherMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","grenadelauncherbonus")
	end

	--rocket launchers: increased power, magazine size. reduced reload time
	if tagCaching.mergedCache["rocketlauncher"] then
		status.setPersistentEffects("rocketlauncherbonus", {
			{stat = "powerMultiplier", effectiveMultiplier = 1 + (masteries.stats.rocketLauncherMastery/2)},
			{stat = "reloadTime", amount = -1/4 * masteries.stats.rocketLauncherMastery},
			--{stat = "magazineMultiplier", effectiveMultiplier = 1 + (masteries.stats.rocketLauncherMastery/2)},
			--{stat = "magazineSize", amount = 2 * masteries.stats.rocketLauncherMastery}
			{stat = "magazineSize", amount = 1/2 * masteries.stats.rocketLauncherMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","rocketlauncherbonus")
	end

	--shotguns: increased Power, Magazine Size, Crit Chance
	if tagCaching.mergedCache["shotgun"] then
		status.setPersistentEffects("shotgunbonus", {
			{stat = "powerMultiplier", effectiveMultiplier = 1 + (masteries.stats.shotgunMastery/2)},
			{stat = "reloadTime", amount = -1/4 * masteries.stats.shotgunMastery},
			--{stat = "magazineMultiplier", effectiveMultiplier = 1 + (masteries.stats.shotgunMastery/2)},
			--{stat = "magazineSize", amount = 2 * masteries.stats.shotgunMastery},
			{stat = "magazineSize", amount = 1/2 * masteries.stats.shotgunMastery},
			{stat = "critChance", amount = 1/4 * masteries.stats.shotgunMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","shotgunbonus")
	end

	--energy weapons: increased Energy
	if tagCaching.mergedCache["energy"] then
		status.setPersistentEffects("energybonus", {
			{stat = "energyMax", effectiveMultiplier = 1 + (masteries.stats.energyMastery/2)}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","energybonus")
	end

	--plasma weapons: increased Crit Damage
	if tagCaching.mergedCache["plasma"] then
		status.setPersistentEffects("plasmabonus", {
			{stat = "critDamage", amount = masteries.stats.plasmaMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","plasmabonus")
	end

	--bioweapons: increased Crit Chance
	if tagCaching.mergedCache["bioweapon"] then
		status.setPersistentEffects("bioweaponbonus", {
			{stat = "critChance", amount = 1/2 * masteries.stats.bioWeaponMastery}
		})
		world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","bioweaponbonus")
	end

	--world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","masterybonus")
	--world.sendEntityMessage(activeItem.ownerEntityId(),"recordFUPersistentEffect","masteryBonus")
	masteries.applied=true
end

function masteries.load()
	masteries.stats=masteries.stats or {}
	--load mastery stats by forced lowercase tag. streamlines shit.
	for tag,_ in pairs(tagCaching.mergedCache) do
		local e=tag:lower().."Mastery"
		masteries.stats[e]=status.stat(e)
	end
	if tagCaching.mergedCache["ranged"] then
		masteries.stats.fireRateMastery = status.stat("fireRateBonus")
		masteries.stats.ammoMastery = status.stat("ammoMastery")
	end
	masteries.loaded=true
end

function masteries.update(dt)
	tagCaching.update(dt)
	masteries.load()
	masteries.apply()
	--sb.logInfo("masteries.update(%s): masteries:%s",dt,masteries)
end