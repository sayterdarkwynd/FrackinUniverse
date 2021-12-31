require "/scripts/augments/item.lua"

function hasTag(input,tag) --checking for ammo tags.
	for _,v in pairs(input) do
		if v == tag then
			return true
		end
	end
	return false
end

function apply(input)
	local output = Item.new(input)

	if output.count > 1 then --no reloading stacks of mags with same bullet. Stacks of ANYTHING, for that matter >:T
		return nil
	end

	if not output:instanceValue("usesAmmo") then
		if output:instanceValue("magazineType") and not config.getParameter("magazineType") then --magazines don't use ammo, but have magazineType
			local outputAmmo = output:instanceValue("ammoCount") or 1
			local outputType = output:instanceValue("ammoType")
			local outputTag  = output:instanceValue("ammoTag")
			local outputMax  = output:instanceValue("ammoMax")

			local outputAmmoRate = output:instanceValue("ammoFireRate") or 1

			local inputAmmo  = config.getParameter("ammoCount") or 1
			local inputType  = config.getParameter("ammoType")
			local inputTag   = config.getParameter("ammoTag")
			local casing     = config.getParameter("ammoCasing") or false
			local ammoName	 = config.getParameter("ammoName")
			local ammoIcon   = config.getParameter("ammoIcon")
			local projectile = config.getParameter("ammoProjectile")
			local pcount	 = config.getParameter("ammoProjectileCount")
			local inputAmmoRate	 = config.getParameter("ammoFireRate")

			--sb.logInfo(inputAmmoRate)
			if (outputAmmo + inputAmmo <= outputMax) and (outputType == inputType or ((outputAmmo == 0) and (outputTag == inputTag))) then
				output:setInstanceValue("ammoCount",outputAmmo + inputAmmo)
				output:setInstanceValue("ammoType", inputType)
				output:setInstanceValue("ammoProjectile",projectile)
				output:setInstanceValue("ammoProjectileCount",pcount)
				output:setInstanceValue("ammoName",ammoName)
				output:setInstanceValue("ammoIcon",ammoIcon)
				output:setInstanceValue("ammoFireRate",inputAmmoRate)
				if casing then
					output:setInstanceValue("ammoCasing",casing)
				else
					output:setInstanceValue("ammoCasing",false)
				end
				return output:descriptor(),1
			else
				return nil
			end
		else
			return nil
		end
	elseif not hasTag(output:instanceValue("ammoTags"),config.getParameter("ammoTag")) then
		return nil
	end

	local outputAmmo = output:instanceValue("ammoAmount")
	local outputMax = output:instanceValue("ammoMax")
	local outputType = output:instanceValue("ammoType")
	local outputMagazine = output:instanceValue("magazineType") or false

	local inputAmmo = config.getParameter("ammoCount") or false
	local inputType = config.getParameter("ammoType")
	local inputMagazine = config.getParameter("magazineType") or false
	local inputCasing = config.getParameter("ammoCasing") or false

	local extraStorage = output:instanceValue("extraAmmoList") or {}


	if outputMagazine and inputMagazine then --if it uses mags, you can't load it with separate bullets. Placing this before the maxammo check since mag can change that
		if outputMagazine ~= "none" then --assuming here that a gun that doesn't have a mag in also doesn't have any ammo
			extraStorage[outputMagazine] = 1 + (extraStorage[outputMagazine] or 0)
			extraStorage[outputType] = outputAmmo  + (extraStorage[outputType] or 0)
		end
		output:setInstanceValue("magazineType",inputMagazine)
		output:setInstanceValue("ammoType",inputType)
		output:setInstanceValue("ammoMax",config.getParameter("ammoMax") or outputMax)

		-- FIXME: found by Luacheck: both "inputAmmoRate" and "outputAmmoRate" are always nil here:
		output:setInstanceValue("ammoFireRate",inputAmmoRate or config.getParameter("ammoFireRate") or outputAmmoRate)

		output:setInstanceValue("ammoAmount",inputAmmo or config.getParameter("ammoMax") or outputMax) --probably won't work right
	elseif not outputMagazine == not not inputMagazine then --hopefuly does xor of "if either of these exists"
		return nil
	else

		if outputAmmo == outputMax and outputType == inputType then --gun has no mag. check if the internal mag is full and is full of same stuff
			return nil
		else
			if outputType ~= inputType then
				extraStorage[outputType] = outputAmmo + (extraStorage[outputType] or 0)
				output:setInstanceValue("ammoType",inputType)
				outputAmmo = 0
			end

			if (outputMax - outputAmmo) < inputAmmo then
				extraStorage[inputType] = inputAmmo - outputMax + outputAmmo
				output:setInstanceValue("ammoAmount",outputMax)
			else
				output:setInstanceValue("ammoAmount",outputAmmo + inputAmmo)
			end
		end

	end

	output:setInstanceValue("ammoName",config.getParameter("ammoName"))
	output:setInstanceValue("ammoIcon",config.getParameter("ammoIcon"))
	output:setInstanceValue("ammoCasing",config.getParameter("ammoCasing") or false)
	output:setInstanceValue("tooltipFields",{ammoNameLabel = config.getParameter("ammoName"),ammoIconImage = config.getParameter("ammoIcon")})
	output:setInstanceValue("extraAmmo", true)
	output:setInstanceValue("extraAmmoList", extraStorage)

	if inputCasing then
		output:setInstanceValue("ammoCasing",inputCasing)
	else
		output:setInstanceValue("ammoCasing",false)
	end

	local ammoProjectile = config.getParameter("ammoProjectile")
	if ammoProjectile then
		local ability = output:instanceValue("primaryAbility")
		ability.projectileType = config.getParameter("ammoProjectile")
		ability.projectileCount = config.getParameter("ammoProjectileCount") or 1
		ability.bonusDps = config.getParameter("ammoDamage") or 0
		--FU addition of fireRate controlled via ammo type
		ability.fireTime = config.getParameter("ammoFireRate")
		output:setInstanceValue("primaryAbility",ability)
	end

	return output:descriptor(),1
end
