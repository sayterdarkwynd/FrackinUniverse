require "/scripts/util.lua"

function craftingRecipe(items)
	if #items ~= 1 then return end
	local item = items[1]
	if not item then return end
	local newParams = copy(item.parameters) or {}
	local itemBaseParams=root.itemConfig(item.name)
	--local oldParts=newParams.animationParts or itemBaseParams.config.animationParts or {}
	local oldParts=util.mergeTable(itemBaseParams.config.animationParts or {},newParams.animationParts or {})
	if not (util.tableSize(oldParts)>0) then return end
	
	local bannedParts={
		"chargeeffect",--want to keep
		"muzzleflash",--want to keep
		"specialarrow","arrow",--these cause bow transform to fail
		"IGNORETHIS"
	}
	--[[local allowedParts={
		"butt","barrel","middle",--guns
		"blade","handle","sword",--swords
		"crown","stone","staff",--staves/wands
		"toplimb","bottomlimb","bow",--bows
		"bugnet",
		"shield","weapon","boomerang","chakram",--genericweaponstuff
		"IGNORETHIS"
	}]]
	local bannedDbg={}
	local allowedDbg={}
	
	if newParams.compressed then
		newParams.compressed=nil
		newParams.muzzleOffset=nil
		newParams.animationCustom=nil
		newParams.animationParts=nil
	else
		newParams.compressed=true
		newParams.muzzleOffset={0,0}
		--newParams.animationCustom=newParams.animationCustom or {}
		--newParams.animationCustom.animatedParts={}
		newParams.animationParts=newParams.animationParts or {}
		if oldParts then
			for partName,partImg in pairs(oldParts) do
				local failed=false
				lPartName=string.lower(partName)
				for _,bannedEntry in pairs(bannedParts) do
					if bannedEntry==lPartName or bannedEntry.."fullbright"==lPartName then
						bannedDbg[partName]=false
						failed=true
						break
					end
				end
				if not failed then
					newParams.animationParts[partName]="/objects/weaponcompressor/invis.png"
					allowedDbg[partName]=true
				end
			
			end
			--newParams.animationParts={muzzleFlash=oldParts.muzzleFlash}
		end
		
		if util.tableSize(newParams.animationParts) == 0 then
			newParams.animationParts=nil
		end
	end
	
	local newItem = {name = item.name,count = item.count,parameters = newParams}
	
	
	
	powerTimer=3.0
	
	retData={input = items,output = newItem,duration = powerTimer}
	
	if not doOnce then
		doOnce=true
		animator.setAnimationState("tetherState", powerTimer and powerTimer > 0 and "on" or "off")
		
		--dbg(util.tableSize(oldParts))
		--dbg(allowedDbg)
		--dbgJ(item)
		--dbgJ(itemBaseParams)
		--dbgJ(retData)
	end
	
	return retData
end

function update(dt)
	powerTimer=(powerTimer and powerTimer > 0) and (powerTimer-dt) or 0
	animator.setAnimationState("tetherState", powerTimer and powerTimer > 0 and "on" or "off")
	doOnce=(powerTimer and powerTimer > 0)
end

function dbgJ(d)
	dbg(sb.printJson(d))
end

function dbg(d)
	sb.logInfo("%s",d)
end