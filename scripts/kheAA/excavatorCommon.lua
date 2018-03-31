require "/scripts/kheAA/transferUtil.lua"

excavatorCommon={}
states={}
reDrillLevelFore=0
redrillPosFore=nil
reDrillLevelback=0
redrillPosBack=nil
deltatime = 0;
local delta2=0
step=0;
time = 0;
--[[
node list:
	storage.logicNode
	storage.pumpHPNode
	storage.outDataNode
	storage.spoutNode
	storage.drillHPNode

]]

function excavatorCommon.init()
	local buffer=""
	transferUtil.init()
	transferUtil.loadSelfContainer()
	if storage.disabled then
		sb.logInfo("excavatorCommon disabled on non-objects (current is \"%s\") for safety reasons.",entityType.entityType())
		return
	end
	storage.facing=util.clamp(object.direction(),0,1)
	storage.isDrill=config.getParameter("kheAA_isDrill",false)
	storage.isPump=config.getParameter("kheAA_isPump",false)
	storage.isVacuum=config.getParameter("kheAA_isVacuum",false)
	
	buffer=config.getParameter("kheAA_excavatorRate")
	storage.excavatorRate=((type(buffer)=="number" and buffer > 0.0) and buffer) or 1.0
	
	step=(step or -0.2)

	if storage.isDrill == true or storage.isPump == true then
		storage.maxDepth=config.getParameter("kheAA_maxDepth",8);
	end
	
	if storage.isPump then
		require "/scripts/kheAA/liquidLib.lua"
		storage.pumpHPNode=config.getParameter("kheAA_powerPumpNode");
		storage.spoutNode=config.getParameter("kheAA_spoutNode");
		storage.depth=0
		liquidLib.init()
	end
	
	if storage.isDrill then
		storage.drillPower=config.getParameter("kheAA_drillPower",8);
		storage.drillHPNode=config.getParameter("kheAA_powerMineNode");
		storage.maxWidth = config.getParameter("kheAA_maxWidth",8);
		storage.width=0
	end
	
	if storage.isVacuum then
		--[[if not world.takeItemDrop then
			storage.isVacuum=false
			sb.logInfo("Vacuum code set to run on client entity. Functionality disabled.")--shouldnt technically ever run.
		else
			storage.vacuumRange=config.getParameter("kheAA_vacuumRange")
		end]]
		storage.vacuumRange=config.getParameter("kheAA_vacuumRange",4)
	end
	
	if storage.isDrill or storage.isPump or storage.isVacuum then
		storage.state="start"
		anims()
	else
		storage.state="off"
	end
end

function excavatorCommon.cycle(dt)
	if storage.disabled then return end
	if not delta2 or delta2 > 1.0 then
		transferUtil.loadSelfContainer()
		if storage.isPump then
			liquidLib.update(dt)
		end
		delta2=0
	else
		delta2=delta2+dt
	end
	if storage.state=="off" then
		setRunning(false)
		return
	end
	
	if transferUtil.powerLevel(storage.logicNode) then
		if storage.state=="stop" then
			setRunning(true)
			storage.state="start"
			return;
		end
	else
		setRunning(false)
		deltatime=0
	end
	setRunning(true)
	deltatime = (deltatime or 100) + dt
	time = (time or (dt*-1)) + dt;
	if time > 10 then
		local pos = storage.position;
		local x1 = world.xwrap(pos[1] - 1);
		local x2 = world.xwrap(pos[1] + 1);
		local rect = {x1, pos[2] - 1, x2, pos[2] + 1}
		world.loadRegion(rect);
		if storage.isDrill then
			x1 = world.xwrap(pos[1] + storage.drillPos[1] - storage.maxWidth)
			x2 = world.xwrap(pos[1] + storage.drillPos[1] + storage.maxWidth)
			rect = {x1, pos[2] + storage.drillPos[2] - 5, x2, pos[2] + storage.drillPos[2] + 5};
			world.loadRegion(rect);
		end
		time=0
	end
	states[storage.state](dt);
end

function states.start(dt)
	if storage.isDrill then
		storage.state="moveDrillBar"
	elseif storage.isPump then
		storage.state="movePump"
	elseif storage.isVacuum then
		storage.state="vacuum"
	end
end

function states.vacuum(dt)
	if transferUtil.powerLevel(storage.logicNode) then
		excavatorCommon.grab(entity.position())
		storage.state="start"
	end
end

function states.moveDrillBar(dt)
	if (deltatime * storage.excavatorRate) >= 0.2 then
		step = step + 0.2;
		deltatime=0
	end
	animator.resetTransformationGroup("horizontal")
	animator.scaleTransformationGroup("horizontal", {storage.width+step,1});
	animator.translateTransformationGroup("horizontal", {2,1});
	if step >= 1 then
		step = 0;
		if (storage.width < storage.maxWidth) then
			local searchPos = {world.xwrap(storage.position[1] + storage.width + 2), storage.position[2] + 1};
			if not world.material(searchPos, "foreground") then
				storage.width = storage.width + 1;
			end
		end
		local searchPos = {world.xwrap(storage.position[1] + storage.width + 2), storage.position[2] + 1};
		if storage.width >= storage.maxWidth or world.material(searchPos, "foreground") then
			animator.setAnimationState("drillState", "on");
			renderDrill(storage.drillPos)
			storage.state = "moveDrill";
			storage.drillTarget = excavatorCommon.getNextDrillTarget();
			setRunning(false);
		end
	end
	
end

function states.moveDrill(dt)
	--local storage.drillPos = storage.drillPos;
	local drillTarget = storage.drillTarget;
	local drillDir = excavatorCommon.getDir();
	if step >= 1 then
		step = 0;
		storage.drillPos[1] = storage.drillPos[1] + drillDir[1];
		storage.drillPos[2] = storage.drillPos[2] + drillDir[2];
		renderDrill({storage.drillPos[1], storage.drillPos[2]})
	end
	if (deltatime * storage.excavatorRate) >= 0.05 then
		step = step + 0.1;
		deltatime = 0;
		renderDrill({storage.drillPos[1] + drillDir[1] * step, storage.drillPos[2] + drillDir[2] * step})
	end
	if storage.drillPos[1] == drillTarget[1] and storage.drillPos[2] == drillTarget[2] then
		if storage.isPump then
			storage.state = "pump";
		else
			storage.state = "mine";
		end
	end
end



function states.movePump(dt)
	if (deltatime * storage.excavatorRate) >= 0.2 then
		step = step + 0.2;
	end
	if step >= 1 then
		step = 0;
		storage.depth = storage.depth - 1;
		storage.state = "pump";
		renderPump(step)
	end
	if (deltatime * storage.excavatorRate) >= 0.1 then
		step = step + 0.1;
		deltatime = 0;
		renderPump(step)
	end
end



function excavatorCommon.grab(grabPos)
	if not storage.vacuumRange then
		if not missingRangeCheck then
			sb.logInfo("Uh-oh, an object at %s is missing vacuum range!",entity.position())
			missingRangeCheck=true
		end
		return
	end
	local drops = world.itemDropQuery(grabPos,storage.vacuumRange);
	--local size=world.containerItemsCanFit(storage.containerId,drops[i])
	for i = 1, #drops do
		local item = world.takeItemDrop(drops[i]);
		if item~=nil then
			transferUtil.throwItemsAt(storage.containerId,storage.inContainers[storage.containerId],item,true)
		end
	end
end



function states.mine(dt)
	if (deltatime * storage.excavatorRate) < 0.1 then
		return;
	end
	deltatime = 0;
	if redrillPosFore ~= nil then
		if reDrillLevelFore == 1 then
			if world.material(redrillPosFore,"foreground") then
				world.damageTileArea(redrillPosFore,1.25, "foreground", redrillPosFore, "plantish", storage.drillPower/3)
				reDrillLevelFore=2
				if storage.isVacuum then
					excavatorCommon.grab(redrillPosFore)
				end
				return
			else
				reDrillLevelFore=0
				redrillPosFore=nil
			end
		elseif reDrillLevelFore == 2 then
			if world.material(redrillPosFore,"foreground") then
				world.damageTileArea(redrillPosFore,1.25, "foreground", redrillPosFore, "plantish", storage.drillPower/3)
				reDrillLevelFore=0
				if storage.isVacuum then
					excavatorCommon.grab(redrillPosFore)
				end
				return
			else
				reDrillLevelFore=0
				redrillPosFore=nil
			end
		end
	end
	if redrillPosBack ~= nil then
		if reDrillLevelBack == 1 then
			if world.material(redrillPosBack,"background") then
				world.damageTileArea(redrillPosBack,1.25, "background", redrillPosBack, "plantish", storage.drillPower/3)
				reDrillLevelBack=2
				if storage.isVacuum then
					excavatorCommon.grab(redrillPosFore)
				end
				return
			else
				reDrillLevelBack=0
				redrillPosBack=nil
			end
		elseif reDrillLevelBack == 2 then
			if world.material(redrillPosBack,"background") then
				world.damageTileArea(redrillPosBack,1.25, "background", redrillPosBack, "plantish", storage.drillPower/3)
				reDrillLevelBack=0
				if storage.isVacuum then
					excavatorCommon.grab(redrillPosBack)
				end
				return
			else
				reDrillLevelBack=0
				redrillPosBack=nil
			end
		end
	end

	local absdrillPos = transferUtil.getAbsPos(storage.drillPos,storage.position);
	if (storage.position[2]-absdrillPos[2]) > storage.maxDepth then
		drillReset()
		anims()
		setRunning(false)
		storage.state="stop"
		return
	end
	if world.material(absdrillPos,"foreground") then
		world.damageTiles({absdrillPos}, "foreground", absdrillPos, "plantish", storage.drillPower)
		if world.material(absdrillPos,"foreground") then
			local weeds=world.entityQuery({absdrillPos[1]-20,absdrillPos[2]-20},{absdrillPos[1]+20,absdrillPos[2]+20})
			if weeds~=nil then
				for k,v in pairs(weeds) do
					if world.entityExists(v) then
					end
				end
				redrillPosFore=absdrillPos;
				reDrillLevelFore=1
				return
			end
		end
	end
	if transferUtil.powerLevel(storage.drillHPNode,true) then
		world.damageTiles({absdrillPos}, "background", absdrillPos, "plantish", storage.drillPower)
		if world.material(absdrillPos,"background") then
			world.damageTiles({absdrillPos}, "background", absdrillPos, "plantish", storage.drillPower)
			if world.material(absdrillPos,"background") then
				redrillPosBack=absdrillPos;
				reDrillLevelBack=1
				return
			end
		end
	end
	storage.drillTarget = excavatorCommon.getNextDrillTarget();
	deltatime=0.1
	storage.state = "moveDrill";
	if storage.isVacuum then
		excavatorCommon.grab(absdrillPos)
	end
	
end

function states.pump(dt)
	if (deltatime * storage.excavatorRate) < 0.2 then
		return;
	end
	deltatime = 0;

	local liquid = world.forceDestroyLiquid(transferUtil.getAbsPos({storage.facing, storage.depth},storage.position));
	if liquid ~= nil then
		if storage.liquids[liquid[1]] == nil then
			storage.liquids[liquid[1]] = 0;
		end
		storage.liquids[liquid[1]] = storage.liquids[liquid[1]] + liquid[2];
	end
	
	if not transferUtil.powerLevel(storage.pumpHPNode,true) then
		for k,v in pairs(storage.liquids) do
			if v >= 1 then
				local level=10^math.floor(math.log(v,10))
				local itemD=liquidLib.liquidToItem(k,level)
				if itemD ~= nil then
					local try,count=transferUtil.throwItemsAt(storage.containerId,storage.inContainers[storage.containerId],itemD)
					if try then
						storage.liquids[k] = storage.liquids[k] - count;
						break
					end
				else
					if util.tableSize(storage.liquidOuts)>0 then
						local outputPipe=transferUtil.findNearest(entity.id(),entity.position(),storage.liquidOuts)
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
		for k,v in pairs(storage.liquids) do
			if v >= 1 then
				local level=10^math.floor(math.log(v,10))
				if util.tableSize(storage.liquidOuts)>0 then
				--findNearest(source,sourcePos,targetList)
					local outputPipe=transferUtil.findNearest(entity.id(),entity.position(),storage.liquidOuts)
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

		end
	end
	if (storage.depth*-1) > storage.maxDepth then
		setRunning(false)
		if storage.isDrill then
			storage.state = "mine";
		end
		return
	end
	if world.material(transferUtil.getAbsPos({storage.facing, storage.depth - 1},storage.position), "foreground") then
		return;
	end
	--[[if world.material(transferUtil.getAbsPos({storage.facing, storage.depth - 2},storage.position), "foreground") then
		return;
	end]]
	if liquid == nil then
		if storage.isDrill then
			storage.state = "moveDrill";
		else
			storage.state = "movePump";
		end
	end
end


function states.stop()
	-- body
end


function excavatorCommon.getNextDrillTarget()
	local pos = storage.position;
	local target = {storage.drillPos[1], storage.drillPos[2]}
	if storage.facing == 1 and target[1] >= storage.width + 1 then
		storage.facing = -1
		target[2] = target[2] - 1;	 
	elseif storage.facing == -1 and target[1] <= 2 then
		storage.facing = 1
		target[2] = target[2] - 1;
	else
		target[1] = target[1] + storage.facing;
	end
	if pos[2] + target[2] <= 1 then
		storage.state = "stop";
	end
	
	storage.drillDir = excavatorCommon.getDir();
	--world.loadRegion({ target[1]-4, target[2]-4, target[1]+4, target[2]+4 })
	return target;
end

function excavatorCommon.getDir()
	local dir = {0,0};
	local drillPos = storage.drillPos;
	local drillTarget = storage.drillTarget;
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
		storage.drillDir = dir;
		return dir;
end

function anims()
	if(animWarn~=true) then
		sb.logInfo("Excavator lib loaded. Your anims, however, are not.")
		animWarn=true
	end
end
