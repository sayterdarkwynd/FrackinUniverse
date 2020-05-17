require "/scripts/util.lua"

function craftingRecipe(items)
	if #items ~= 1 then return end
	local item = items[1]
	if not item then return end
	local newParams = copy(item.parameters) or {}
	local itemBaseParams=root.itemConfig(item.name)
	itemLevel=item.parameters.level or itemBaseParams.config.level
	specialsSeed=item.parameters.seed or itemBaseParams.config.seed or os.time()
	
	newSeed=math.abs(sb.staticRandomI32(specialsSeed))
	local randoItem=root.createItem(item.name,itemLevel,newSeed)
	
	
	local newItem = {name = item.name,count = item.count,parameters = newParams}
	powerTimer=3.0
	--retData={input = items,output = newItem,duration = powerTimer}
	retData={input = items,output = randoItem,duration = powerTimer}
	
	if not doOnce then
		doOnce=true
		dbgJ(item)
		dbgJ(randoItem)
		dbg({specialsSeed,newSeed})
		--dbg({itemLevel=itemLevel})
		--dbgJ(itemBaseParams)
		dbgJ(retData)
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