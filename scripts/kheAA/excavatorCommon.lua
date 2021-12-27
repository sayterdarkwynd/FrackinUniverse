require "/scripts/kheAA/transferUtil.lua"
require "/scripts/vec2.lua"

excavatorCommon={
	mainDelta = 0,
	loadSelfTimer=0
}
states={}
reDrillLevelFore=0
redrillPosFore=nil
reDrillLevelback=0
redrillPosBack=nil
--redrill: two damage instances. one at target, one in T from target. damage = <stats>*mult/max. max: cap for a counter incremented by 1 per redrill attempt.
redrillMax=6
redrillMult=1.0
step=0
time = 0
--[[
node list:
	transferUtil.vars.logicNode
	excavatorCommon.vars.pumpHPNode
	transferUtil.vars.outDataNode
	excavatorCommon.vars.spoutNode
	excavatorCommon.vars.drillHPNode

]]

function excavatorCommon.init()
	local buffer=""
	transferUtil.loadSelfContainer()
	if self.disabled then
		storage.state="disabled"
		sb.logInfo("excavatorCommon disabled on non-objects (current is \"%s\") for safety reasons.",entityType.entityType())
		return
	end
	excavatorCommon.vars={}
	excavatorCommon.vars.direction=util.clamp(object.direction(),0,1)
	excavatorCommon.vars.facing=object.direction()
	excavatorCommon.vars.isDrill=config.getParameter("kheAA_isDrill",false)
	excavatorCommon.vars.isPump=config.getParameter("kheAA_isPump",false)
	excavatorCommon.vars.isVacuum=config.getParameter("kheAA_isVacuum",false)

	buffer=config.getParameter("kheAA_excavatorRate")
	excavatorCommon.vars.excavatorRate=((type(buffer)=="number" and buffer > 0.0) and buffer) or 1.0

	step=(step or -0.2)

	if excavatorCommon.vars.isDrill == true or excavatorCommon.vars.isPump == true then
		excavatorCommon.vars.maxDepth=config.getParameter("kheAA_maxDepth",8)
	end

	if excavatorCommon.vars.isPump then
		require "/scripts/kheAA/liquidLib.lua"
		excavatorCommon.vars.pumpHPNode=config.getParameter("kheAA_powerPumpNode")
		excavatorCommon.vars.spoutNode=config.getParameter("kheAA_spoutNode")
		storage.depth=0 -- rather have it X=X or 0, but that causes problems when the pumps reinit in a partially loaded chunk they start ignoring floors.
		--storage.pumpThrottler=storage.pumpThrottler or 0
		--excavatorCommon.vars.throttleInfinite=excavatorCommon.vars.throttleInfinite or false
		liquidLib.init()
	end

	if excavatorCommon.vars.isDrill then
		excavatorCommon.vars.drillPower=config.getParameter("kheAA_drillPower",8)
		excavatorCommon.vars.drillHPNode=config.getParameter("kheAA_powerDrillNode")
		excavatorCommon.vars.maxWidth = config.getParameter("kheAA_maxWidth",8)
		storage.width=storage.width or 0
	end

	if excavatorCommon.vars.isVacuum then
		excavatorCommon.vars.vacuumRange=config.getParameter("kheAA_vacuumRange",4)
		excavatorCommon.vars.vacuumDelay=config.getParameter("kheAA_vacuumDelay",0)--in seconds
	end

	if excavatorCommon.vars.isDrill or excavatorCommon.vars.isPump or excavatorCommon.vars.isVacuum then
		storage.state=storage.state or "start"
		anims()
	else
		storage.state="off"
	end
end

function excavatorCommon.cycle(dt)
	if self.disabled then return end
	if not excavatorCommon.loadSelfTimer or excavatorCommon.loadSelfTimer > 1.0 then
		transferUtil.loadSelfContainer()
		if excavatorCommon.vars.isPump then
			liquidLib.update(dt)
		end
		excavatorCommon.loadSelfTimer=0
	else
		excavatorCommon.loadSelfTimer=excavatorCommon.loadSelfTimer+dt
	end

	if storage.state=="off" or not transferUtil.powerLevel(transferUtil.vars.logicNode) then
		setRunning(false)
		excavatorCommon.mainDelta=0
		return
	elseif transferUtil.powerLevel(transferUtil.vars.logicNode) then
		if storage.state=="stop" then
			setRunning(true)
			storage.state="start"
			return
		end
	end

	excavatorCommon.mainDelta = (excavatorCommon.mainDelta or 100) + dt--DO NOT INCREMENT ELSEWHERE
	if not storage.state then
		excavatorCommon.init()
		return
	end
	if storage.state=="disabled" then return end
	setRunning(true)
	time = (time or (dt*-1)) + dt
	if time > 10 then
		local pos = storage.position
		local x1 = world.xwrap(pos[1] - 1)
		local x2 = world.xwrap(pos[1] + 1)
		local rect = {x1, pos[2] - 1, x2, pos[2] + 1}
		world.loadRegion(rect)
		if excavatorCommon.vars.isDrill then
			x1 = world.xwrap(pos[1] + storage.drillPos[1] - excavatorCommon.vars.maxWidth)
			x2 = world.xwrap(pos[1] + storage.drillPos[1] + excavatorCommon.vars.maxWidth)
			rect = {x1, pos[2] + storage.drillPos[2] - 5, x2, pos[2] + storage.drillPos[2] + 5}
			world.loadRegion(rect)
		end
		time=0
	end
	states[storage.state](dt)
end

function states.disabled(dt)
	return
end

function states.start(dt)
	if excavatorCommon.vars.isDrill then
		storage.state="moveDrillBar"
	elseif excavatorCommon.vars.isPump then
		storage.state="movePump"
	elseif excavatorCommon.vars.isVacuum then
		storage.state="vacuum"
	end
	storage.box=transferUtil.findCorners()
end

function states.vacuum(dt)
	if transferUtil.powerLevel(transferUtil.vars.logicNode) then
		if excavatorCommon.mainDelta > excavatorCommon.vars.vacuumDelay then
			local buffer=entity.position()
			--if excavatorCommon.vacuumSafetyCheck(entity.position()) then
			if buffer then
				excavatorCommon.grab(buffer)
			end
			--end
			excavatorCommon.mainDelta=0
			storage.state="start"
		end
	else
		excavatorCommon.mainDelta=0
	end
end

function states.moveDrillBar(dt)
	if (excavatorCommon.mainDelta * excavatorCommon.vars.excavatorRate * 2.0) >= 0.2 then
		step = step + 0.2
		excavatorCommon.mainDelta=0
	end
	animator.resetTransformationGroup("horizontal")
	animator.scaleTransformationGroup("horizontal", {storage.width+step,1})
	animator.translateTransformationGroup("horizontal", {2,1})
	if step >= 1 then
		step = 0
		if (storage.width < excavatorCommon.vars.maxWidth) then
			local searchPos = {world.xwrap(storage.position[1] + storage.width + 2), storage.position[2] + 1}
			if not world.material(searchPos, "foreground") then
				storage.width = storage.width + 1
			end
		end
		local searchPos = {world.xwrap(storage.position[1] + storage.width + 2), storage.position[2] + 1}
		if storage.width >= excavatorCommon.vars.maxWidth or world.material(searchPos, "foreground") then
			animator.setAnimationState("drillState", "on")
			renderDrill(storage.drillPos)
			storage.state = "moveDrill"
			storage.drillTarget = excavatorCommon.getNextDrillTarget()
			setRunning(false)
		end
	end

end

function states.moveDrill(dt)
	--local storage.drillPos = storage.drillPos
	local drillTarget = storage.drillTarget
	local drillDir = excavatorCommon.getDir()
	if step >= 1 then
		step = 0
		storage.drillPos[1] = storage.drillPos[1] + drillDir[1]
		storage.drillPos[2] = storage.drillPos[2] + drillDir[2]
		renderDrill({storage.drillPos[1], storage.drillPos[2]})
	end
	if (excavatorCommon.mainDelta * excavatorCommon.vars.excavatorRate) >= 0.05 then
		step = step + 0.1
		excavatorCommon.mainDelta = 0
		renderDrill({storage.drillPos[1] + drillDir[1] * step, storage.drillPos[2] + drillDir[2] * step})
	end
	if storage.drillPos[1] == drillTarget[1] and storage.drillPos[2] == drillTarget[2] then
		if excavatorCommon.vars.isPump then
			storage.state = "pump"
		else
			storage.state = "mine"
		end
	end
end

function states.movePump(dt)
	if (excavatorCommon.mainDelta * excavatorCommon.vars.excavatorRate) >= 0.2 then
		step = step + 0.2
	end
	if step >= 1 then
		step = 0
		storage.depth = storage.depth - 1
		storage.state = "pump"
		renderPump(step)
	end
	if (excavatorCommon.mainDelta * excavatorCommon.vars.excavatorRate) >= 0.1 then
		step = step + 0.1
		excavatorCommon.mainDelta = 0
		renderPump(step)
	end
end

function excavatorCommon.grab(grabPos)
	if not grabPos then
		return
	end

	if not entity.entityType() == "object" then
		sb.logInfo("excavatorCommon.grab: Cannot run on non-object (id: %s). Stop trying to do so.",entity.id())
		return
	end
	if not excavatorCommon.vars.vacuumRange then
		if not missingRangeCheck then
			sb.logInfo("Uh-oh, an object at %s is missing vacuum range!",entity.position())
			missingRangeCheck=true
		end
		return
	end
	local drops = world.itemDropQuery(grabPos,excavatorCommon.vars.vacuumRange)
	--local size=world.containerItemsCanFit(transferUtil.vars.containerId,drops[i])
	for _,id in pairs(drops) do
		--if entity.entityInSight(drops[i])
		local item = world.takeItemDrop(id)
		if item~=nil then
			local result,countSent,dropped=transferUtil.throwItemsAt(transferUtil.vars.containerId,transferUtil.vars.inContainers[transferUtil.vars.containerId],item,true)
			--sb.logInfo("result: %s, countSent: %s, dropped: %s",result,countSent,dropped)
			if dropped then--throttle control. no effect if no vac delay (such as on quarries and pumps)
				excavatorCommon.mainDelta=excavatorCommon.vars.vacuumDelay*-1
			end
		end
	end
end

--[[function excavatorCommon.vacuumSafetyCheck(grabPos)
	if entity.entityType()~="object" then
		sb.logInfo("excavatorCommon.vacuumSafetyCheck: vacuum code disabled for nonobjects.")
		return false
	end--idiotproofing
	if not excavatorCommon.vars.vacuumRange then
		if not missingRangeCheck then
			sb.logInfo("Uh-oh, an object at %s is missing vacuum range!",entity.position())
			missingRangeCheck=true
		end
		return
	end
	local objects = world.objectQuery(grabPos,excavatorCommon.vars.vacuumRange,{order = "nearest",withoutEntityId = entity.id()})--,callScript = "config.getParameter",callScriptArgs = "kheAA_vacuumRange", callScriptResult <???>
	for _,id in pairs(objects) do
		if world.entityExists(id) then
			local range=world.getObjectParameter(id,"kheAA_isVacuum") and world.getObjectParameter(id,"kheAA_vacuumRange")
			if range then
				--vec2f entity.distanceToEntity
				--sb.logInfo("Range of %s: %s",id,range)
			end
		end
	end
	return true
end]]

function states.mine(dt)
	if (excavatorCommon.mainDelta * excavatorCommon.vars.excavatorRate) < 0.1 then
		return
	end
	excavatorCommon.mainDelta = 0
	if redrillPosFore then
		if reDrillLevelFore > 0 then
			if world.material(redrillPosFore,"foreground") then
				local damage=redrillMult*excavatorCommon.vars.drillPower*math.max(reDrillLevelFore,1)/redrillMax
				world.damageTiles({vec2.add(redrillPosFore,{-1,0}),vec2.add(redrillPosFore,{1,0}),vec2.add(redrillPosFore,{0,-1}),redrillPosFore}, "foreground", redrillPosFore, "plantish",damage)
				world.damageTiles({redrillPosFore}, "foreground", redrillPosFore, "plantish",damage)
				reDrillLevelFore=math.min(reDrillLevelFore+1,redrillMax)
				if excavatorCommon.vars.isVacuum then
					excavatorCommon.grab(redrillPosFore)
				end
				return
			else
				reDrillLevelFore=0
				redrillPosFore=nil
			end
		end
	end
	if redrillPosBack then
		if reDrillLevelBack > 0 then
			if world.material(redrillPosBack,"background") then
				local damage=redrillMult*excavatorCommon.vars.drillPower*math.max(reDrillLevelBack,1)/redrillMax
				world.damageTiles({vec2.add(redrillPosBack,{-1,0}),vec2.add(redrillPosBack,{1,0}),vec2.add(redrillPosBack,{0,-1}),redrillPosBack}, "background", redrillPosBack, "plantish",damage)
				world.damageTiles({redrillPosBack}, "background", redrillPosBack, "plantish",damage)
				reDrillLevelBack=math.min(reDrillLevelBack+1,redrillMax)
				if excavatorCommon.vars.isVacuum then
					excavatorCommon.grab(redrillPosBack)
				end
				return
			else
				reDrillLevelBack=0
				redrillPosBack=nil
			end
		end
	end

	if storage.drillPos[2] < (-1 * excavatorCommon.vars.maxDepth) then
		--sb.logInfo(".p %s, .mD %s",storage.position,excavatorCommon.vars.maxDepth)
		drillReset()
		anims()
		setRunning(false)
		storage.state="stop"
		return
	end
	local absdrillPos = excavatorCommon.combineWrap({storage.drillPos,storage.position})
	if world.material(absdrillPos,"foreground") then
		world.damageTiles({absdrillPos}, "foreground", absdrillPos, "plantish", excavatorCommon.vars.drillPower)
		if world.material(absdrillPos,"foreground") then
			local weeds=world.objectQuery({absdrillPos[1]-1,absdrillPos[2]-1},{absdrillPos[1]+1,absdrillPos[2]+1})
			if weeds then
				local cut=false
				for k,v in pairs(weeds) do
					if world.entityExists(v) then
						cut=true
						break
					end
				end
				if cut then
					reDrillLevelFore=0.1
				else
					reDrillLevelFore=1
				end
				redrillPosFore=absdrillPos
				return
			end
		end
	end
	if transferUtil.powerLevel(excavatorCommon.vars.drillHPNode,true) then
		world.damageTiles({absdrillPos}, "background", absdrillPos, "plantish", excavatorCommon.vars.drillPower)
		if world.material(absdrillPos,"background") then
			world.damageTiles({absdrillPos}, "background", absdrillPos, "plantish", excavatorCommon.vars.drillPower)
			if world.material(absdrillPos,"background") then
				redrillPosBack=absdrillPos
				reDrillLevelBack=1
				return
			end
		end
	end
	storage.drillTarget = excavatorCommon.getNextDrillTarget()
	excavatorCommon.mainDelta=0.1
	storage.state = "moveDrill"
	if excavatorCommon.vars.isVacuum then
		if absdrillPos then
			excavatorCommon.grab(absdrillPos)
		end
	end

end

function states.pump(dt)
	if (excavatorCommon.mainDelta * excavatorCommon.vars.excavatorRate) < 0.2 then
		return
	end

	local tempDelta=excavatorCommon.mainDelta
	excavatorCommon.mainDelta = 0

	--storage.pumpThrottler=math.max(storage.pumpThrottler-(tempDelta*excavatorCommon.vars.excavatorRate*2),0)
	if not storage.box then
		storage.state="start"
		return
	end
	local pos = excavatorCommon.combineWrap({{excavatorCommon.vars.facing, storage.depth},storage.position,{excavatorCommon.vars.facing==-1 and storage.box.xMax or 0,0}})
	local liquid = world.forceDestroyLiquid(pos)

	if liquid then
		--[[storage.pumpThrottler=storage.pumpThrottler+liquid[2]
		if world.liquidAt(pos) then
			excavatorCommon.vars.throttleInfinite=true
		else
			excavatorCommon.vars.throttleInfinite=false
		end]]
		if storage.liquids[liquid[1]] == nil then
			storage.liquids[liquid[1]] = 0
		end
		storage.liquids[liquid[1]] = storage.liquids[liquid[1]] + liquid[2]
	else
		--excavatorCommon.vars.throttleInfinite=false
	end

	if not transferUtil.powerLevel(excavatorCommon.vars.pumpHPNode,true) then
		for k,v in pairs(storage.liquids) do
			if v >= 1 then
				local level=10^math.floor(math.log(v,10))
				local itemD=liquidLib.liquidToItem(k,level)
				if itemD then
					local try,count=transferUtil.throwItemsAt(transferUtil.vars.containerId,transferUtil.vars.inContainers[transferUtil.vars.containerId],itemD)
					if try then
						storage.liquids[k] = storage.liquids[k] - count
						break
					end
				else
					if util.tableSize(excavatorCommon.vars.liquidOuts or {})>0 then
						local outputPipe=transferUtil.findNearest(entity.id(),entity.position(),excavatorCommon.vars.liquidOuts)
						if world.entityExists(outputPipe) then
							world.callScriptedEntity(outputPipe,"liquidLib.receiveLiquid",{k,1})
							storage.liquids[k]=v-1
							break
						end
					end
				end
			end
		end
	else
		for _,item in pairs(world.containerItems(entity.id())) do
			if item.count >= 1 then
				item.count=10^math.floor(math.log(item.count,10))
				local id=liquidLib.itemToLiquidId(item)
				if id then
					if world.containerConsume(entity.id(),item) then
						if not storage.liquids[id] then storage.liquids[id] = 0 end
						storage.liquids[id]=storage.liquids[id]+item.count
						break
					end
				end
			end
		end
		--[[
		for k,v in pairs(storage.liquids) do
			if v >= 1 then
				local level=10^math.floor(math.log(v,10))
				sb.logInfo("t %s",excavatorCommon.vars.liquidOuts)
				if util.tableSize(excavatorCommon.vars.liquidOuts)>0 then
				--findNearest(source,sourcePos,targetList)
					local outputPipe=transferUtil.findNearest(entity.id(),entity.position(),excavatorCommon.vars.liquidOuts)
					--sb.logInfo(sb.printJson({outputPipe,"liquidLib.receiveLiquid",{k,1}}))
					if world.entityExists(outputPipe) then
						world.callScriptedEntity(outputPipe,"liquidLib.receiveLiquid",{k,level})
						storage.liquids[k]=v-level
						break
					end
				end
			end
		end
		for k,v in pairs(storage.liquids) do

		end]]
	end

	--[[if excavatorCommon.vars.throttleInfinite or (storage.pumpThrottler > (tempDelta * 10 * excavatorCommon.vars.excavatorRate)) then
		storage.state="pumpStutter"
		return
	end]]

	if (storage.depth*-1) > excavatorCommon.vars.maxDepth then
		setRunning(false)
		if excavatorCommon.vars.isDrill then
			storage.state = "mine"
		end
		return
	end
	if world.material({pos[1],pos[2]-1}, "foreground") then
		return
	end
	if liquid == nil then
		if excavatorCommon.vars.isDrill then
			storage.state = "moveDrill"
		else
			storage.state = "movePump"
		end
	end
end

--[[function states.pumpStutter(dt)
	if (excavatorCommon.mainDelta * excavatorCommon.vars.excavatorRate) < 0.2 then
		return
	end
	local tempDelta=excavatorCommon.mainDelta
	excavatorCommon.mainDelta = 0

	storage.pumpThrottler = math.max(storage.pumpThrottler - (tempDelta * (excavatorCommon.vars.throttleInfinite and 0.5 or 1) * excavatorCommon.vars.excavatorRate),0)

	if storage.pumpThrottler > excavatorCommon.vars.excavatorRate then
		return
	end

	excavatorCommon.mainDelta = 0
	storage.state="pump"
end]]

function states.stop()
	-- body
end

function excavatorCommon.getNextDrillTarget()
	local pos = storage.position
	local target = {storage.drillPos[1], storage.drillPos[2]}
	if excavatorCommon.vars.direction == 1 and target[1] >= storage.width + 1 then
		excavatorCommon.vars.direction = -1
		target[2] = target[2] - 1
	elseif excavatorCommon.vars.direction == -1 and target[1] <= 2 then
		excavatorCommon.vars.direction = 1
		target[2] = target[2] - 1
	else
		target[1] = target[1] + excavatorCommon.vars.direction
	end
	if pos[2] + target[2] <= 1 then
		storage.state = "stop"
	end

	storage.drillDir = excavatorCommon.getDir()
	--world.loadRegion({ target[1]-4, target[2]-4, target[1]+4, target[2]+4 })
	return target
end

function excavatorCommon.getDir()
	local dir = {0,0}
	local drillPos = storage.drillPos
	local drillTarget = storage.drillTarget
		if drillTarget[1] > drillPos[1] then
			dir[1] = 1
		elseif drillTarget[1] < drillPos[1] then
			dir[1] = -1
		end
		if drillTarget[2] > drillPos[2] then
			dir[2] = 1
		elseif drillTarget[2] < drillPos[2] then
			dir[2] = -1
		end
		storage.drillDir = dir
		return dir
end

function anims()
	if(animWarn~=true) then
		sb.logInfo("Excavator lib loaded. Your anims, however, are not.")
		animWarn=true
	end
end

function excavatorCommon.combineWrap(argList)
	local buffer={0,0}
	for _,pos in pairs(argList) do
		buffer=vec2.add(buffer,pos or {0,0})
	end
	buffer[1]=world.xwrap(buffer[1])
	--sb.logInfo("%s",buffer)
	return buffer
end

function transferUtil.findCorners()
	local rVal={xMin=0,yMin=0,xMax=0,yMax=0}
	for _,v in pairs(object.spaces()) do
		if rVal.xMin > v[1] then
			rVal.xMin=v[1]
		end
		if rVal.yMin > v[2] then
			rVal.yMin=v[2]
		end
		if rVal.xMax < v[1] then
			rVal.xMax=v[1]
		end
		if rVal.yMax < v[2] then
			rVal.yMax=v[2]
		end
	end
	return rVal
end
