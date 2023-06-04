require "/scripts/util.lua"

function charge()
	--magazine:root.itemConfig().config = {<...>,ammoType: psionichealammo, ammoCasing: , tooltipKind: fuammoitem, ammoMax: 10, rarity: rare, magazineType: psionichealmagammo,<...>}
	--ammo:root.itemConfig().config = {<...>,itemName: psionichealammo, ammoCount: 1,<...>}

	ammoConfig=root.itemConfig(ammo).config
	magazineConfig=root.itemConfig(magazine).config

	if not ammoConfig or not magazineConfig then return end
	if (magazine.parameters.ammoType and (magazine.parameters.ammoType == ammo.name)) or (magazineConfig.ammoType and (magazineConfig.ammoType == ammo.name)) then
		local currentMag=magazine.parameters.ammoCount or 0
		if currentMag<(magazineConfig.ammoMax or 0) then
			local ammoWeight=(ammo.parameters.ammoCount or ammoConfig.ammoCount)
			local ammoRequiredPerMag=math.floor((magazineConfig.ammoMax-currentMag)/ammoWeight)
			local ammoAvailablePerMag=math.floor(ammo.count/magazine.count)
			local ammoUsedPerMag=math.min(ammoAvailablePerMag,ammoRequiredPerMag)

			if ammoUsedPerMag>=1 then
				magazine.parameters.ammoCount=currentMag+(ammoUsedPerMag*ammoWeight)

				world.containerTakeNumItemsAt(entity.id(),0,ammoUsedPerMag*magazine.count)
				world.containerTakeAt(entity.id(),1)
				world.containerPutItemsAt(entity.id(),magazine,1)
			end
		end
	end

	ammo=nil
	magazine=nil
end

function update(dt)
	if not deltaTime or (deltaTime > 1) then
		for slot,item in pairs(world.containerItems(entity.id())) do
			if slot == 1 then ammo = item end
			if slot == 2 then magazine = item end
		end

		if ammo and magazine then
			if magazine.count>=1 then
				charge()
			end
		end
	else
		deltaTime=deltaTime+dt
	end
end
