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

	if output:instanceValue("usesAmmo") then --no unloading mags, sadly
		local extraStorage = output:instanceValue("extraAmmoList") or {}
		local outputAmmo = output:instanceValue("ammoAmount")
		local outputType = output:instanceValue("ammoType")
		local outputMagazine = output:instanceValue("magazineType") or false
		extraStorage["unloaderammo"] = 1 + (extraStorage["unloaderammo"] or 0)
		extraStorage[outputType] = outputAmmo + (extraStorage[outputType] or 0)
		if outputMagazine then
			extraStorage[outputMagazine] = 1 + (extraStorage[outputMagazine] or 0)
			output:setInstanceValue("magazineType","none")
		end
		output:setInstanceValue("ammoAmount",0)
		output:setInstanceValue("ammoCasing", false)
		output:setInstanceValue("extraAmmo", true)
		output:setInstanceValue("extraAmmoList", extraStorage)
	else
		return nil
	end

	return output:descriptor(),1
end