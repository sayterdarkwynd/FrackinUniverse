require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.active = false
  harvestBlacklist = {}
	waterBlacklist = {}
	pendingDrops = {}
	bugSpawn = nil
	self.scriptBug = nil
	self.distance = config.getParameter("harvestDistance") or 40
	removableMods = {
	["ash"] = true,
	["blackash"] = true,
	["bone"] = true,
	["grass"] = true,
	["undergrowth"] = true,
	["tar"] = true,
	["sulphur"] = true,
	["roots"] = true,
	["sand"] = true,
	["snow"] = true,
	["tilleddry"] = true
	}
	laserColors  = {
	["till"] = {["color"] = {200,200,255,220}, ["width"] = 0.75},
	["harvest3"] = {["child"] = "harvest2", ["color"] = {100,255,100,255}, ["width"] = 1.25},
	["harvest2"] = {["child"] = "harvest1", ["color"] = {100,255,100,210}, ["width"] = 1.0},
	["harvest1"] = {["color"] = {100,255,100,170}, ["width"] = 0.75},
	}
  self.cooldownTimer = 0
  self.lines = {}
  updateAim()
end

function update(dt, fireMode, shiftHeld)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  updateAim()
  beamgunUpdate(dt)
  if fireMode == "primary"
    and self.cooldownTimer == 0 then
    fireBeam(true)
  elseif fireMode == "alt" 
	and self.cooldownTimer == 0 then
	fireBeam(false)
  end
  local lineList = {}
  for _,n in pairs(self.lines) do
	table.insert(lineList, {line = {vec2.sub(n.line[1], mcontroller.position()), vec2.sub(n.line[2], mcontroller.position())}, width = n.width, color = n.color, position = mcontroller.position(), fullbright = true})
  end
  activeItem.setScriptedAnimationParameter("lineList", lineList)
end

function uninit()

end

function updateAim()
	self.aimAngle = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
	if activeItem.ownerAimPosition()[1] <= mcontroller.position()[1] then
		self.aimDirection = -1
	else
		self.aimDirection = 1
	end
	activeItem.setArmAngle(self.aimAngle)
	activeItem.setFacingDirection(self.aimDirection)
	local oldLines = self.lines
	self.lines = {}
	for _,n in pairs(oldLines) do
		addLine(n.child, n.line)
	end
end


function aimVector(inaccuracy)
  return vec2.rotate({self.aimDirection, 0}, self.aimAngle + sb.nrand(inaccuracy, 0))
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("beamgun", "firePoint")))
  --return vec2.add(mcontroller.position(), vec2.rotate({2.0,0}, self.aimAngle))
end

function beamgunUpdate(dt)
	if self.owner == nil then
		self.owner = world.playerQuery(mcontroller.position(), 0.2)[1]
	end
	if type(bugSpawn) == "number" then
		if bugSpawn <= 0 then
			bugSpawn = bugSpawn - 1
		else
			bugSpawn = nil
		end
	end
	if self.scriptBug == nil or not world.entityExists(self.scriptBug) then
		if bugSpawn == nil then
			world.spawnMonster("hbeamscriptbug", mcontroller.position(), {scripts = {"/scripts/vec2.lua", "/items/active/unsorted/HarvesterBeam/hbeamscriptbug.lua"}})
			bugSpawn = 10
		end
		local buglist = world.monsterQuery(mcontroller.position(), 20)
		for i,j in ipairs(buglist) do
			if world.monsterType(j) == "hbeamscriptbug" then
				self.scriptBug = j
				break
			end
		end
	else
		world.sendEntityMessage(self.scriptBug, "keepAlive")
		--world.callScriptedEntity(self.scriptBug, "keepAlive")
	end
	
	local newItems = world.getProperty("HarvesterBeamgunItemDropList") or {}
	world.setProperty("HarvesterBeamgunItemDropList", nil)
	for id,drop in pairs(newItems) do
		--sb.logInfo("New Drop: %s, %s", id, drop)
		pendingDrops[id] = drop
	end
	
	for id,drop in pairs(pendingDrops) do
		if drop.cd <= 0 then 
			world.spawnItem(drop.data.name, mcontroller.position(), drop.data.count, drop.data.parameters)
			pendingDrops[id] = nil
		else
			pendingDrops[id] = {["data"] = drop.data, ["cd"] = drop.cd - dt}
		end
	end
	
	if harvestBlacklist ~= {} then
		for i,j in pairs(harvestBlacklist) do
			if j[1] < 5 then
				harvestBlacklist[i][1] = j[1] + dt
				if j[4] == "replant" and j[1] >= 0.25 then
					lookForDrops(j[2],j[3],4)
					harvestBlacklist[i][4] = false
					--sb.logInfo("Place: %s, %s, %s, %s", j[3], j[2], self.aimDirection)
					world.placeObject(j[3], j[2], self.aimDirection)
				elseif j[4] == "farm" and j[1] >= 0.25 then
					lookForDrops(j[2],j[3],4)
					harvestBlacklist[i][4] = false
				elseif j[4] == "plant" and j[1] >= 3 then
					lookForDrops(j[2],j[3],30)
					harvestBlacklist[i][4] = false
				end
			else
				harvestBlacklist[i] = nil
			end
		end
	end
	if d ~= {} then
		for i, j in pairs(waterBlacklist) do
			if j[1] < 2 then
				waterBlacklist[i][1] = j[1] + dt
			else
				waterBlacklist[i] = nil
			end
		end
	end
end

function addLine(name, line)
	if name and laserColors[name] then
		table.insert(self.lines, {child = laserColors[name].child, color = laserColors[name].color, width = laserColors[name].width, line = line})
	end
end

function fireBeam(primary)
	if self.owner == nil then return nil end
	local armPos = firePosition()
	local toPointer = vec2.sub(armPos, vec2.mul(vec2.norm(world.distance(armPos, activeItem.ownerAimPosition())), self.distance))
	local blockCheck = world.collisionBlocksAlongLine(armPos, toPointer, {"Null", "Block", "Dynamic"}, 1)
	if blockCheck[1] ~= nil then
		local blockSide = 0
		if world.distance(mcontroller.position(), blockCheck[1])[1] < 0 then
				blockSide = 0
		else
				blockSide = 1
		end
		local tempWallX = {vec2.add(blockCheck[1], {blockSide, 0}), vec2.add(blockCheck[1], {blockSide, 1})}
		if world.distance(mcontroller.position(), blockCheck[1])[2] < 0 then
				blockSide = 0
		else
				blockSide = 1
		end
		local tempWallY = {vec2.add(blockCheck[1], {0, blockSide}), vec2.add(blockCheck[1], {1, blockSide})}
		world.debugLine(tempWallX[1], tempWallX[2], "green")
		world.debugLine(tempWallY[1], tempWallY[2], "green")
		toPointer = vec2.intersect(armPos, toPointer, tempWallX[1], tempWallX[2]) or toPointer
		toPointer = vec2.intersect(armPos, toPointer, tempWallY[1], tempWallY[2]) or toPointer
	end
	world.debugLine(armPos, toPointer, "blue")
	--self.lines = {{line = {armPos, toPointer}, color = {255,255,255}}}
	if primary then
		self.cooldownTimer = 0.5
		animator.playSound("harvest")
		addLine("harvest3", {armPos, toPointer})
		local farmQuery = world.entityLineQuery(armPos, toPointer,{inSightOf = self.owner})
		for i,j in pairs(farmQuery) do
				--sb.logInfo("%s", world.getObjectParameter(j, "objectName"))
				local plantStage = world.farmableStage(j)
				--sb.logInfo("%s, %s at %s: %s, %s, %s", j, world.entityType(j), world.entityPosition(j), world.farmableStage(j), world.entityName(j), world.getObjectParameter(j, "hasObjectItem"))
				local plantName = world.entityName(j)
				local plantConfig = {}
				if plantName and world.entityType(j) == "object" and (world.getObjectParameter(j, "hasObjectItem") == nil or world.getObjectParameter(j, "hasObjectItem")) and world.entityName(j) ~= "sapling" then
					plantConfig = root.itemConfig(plantName).config or {}
				end
				if plantName == "mothtrap" then
					sb.logInfo("Moth Drop?")
					world.sendEntityMessage(self.scriptBug, "callScript", j, "dropHarvest")
					plantStage = "mothtrap"
				elseif plantName and plantConfig.objectType ~= "farmable" then
					plantName = nil
				end
				--sb.logInfo("%s, %s", plantName, plantConfig)
				if type(plantStage) == "number" and waterBlacklist[j] == nil then
					world.spawnProjectile("watersprinkledroplet", vec2.add(world.entityPosition(j), {0,1}), self.owner, {0,-1}, false, {timeToLive = 0.2})
					waterBlacklist[j] = {0}
				end
				if plantStage ~= nil and harvestBlacklist[j] == nil then
					harvestBlacklist[j] = {0, world.entityPosition(j), plantName, "farm"}
					world.damageTiles({world.entityPosition(j)}, "foreground", world.entityPosition(j), "plantish", 0.2, 1)
					if plantConfig.stages and not plantConfig.stages[#plantConfig.stages].resetToStage then
						harvestBlacklist[j][4] = "replant"
					end
				elseif world.entityType(j) == "plant" and harvestBlacklist[j] == nil then
					local shouldDamage = false
					local subCheck = world.entityQuery(vec2.add(world.entityPosition(j),{0,4}), 0.4) 
					for _,id in pairs(subCheck) do
						if id == j then
							shouldDamage = true
							break
						end
					end
					if not shouldDamage then
						subCheck = world.entityQuery(vec2.add(world.entityPosition(j),{0,-2}), 0.4) 
						for _,id in pairs(subCheck) do
							if id == j then
								shouldDamage = true
								break
							end
						end
					end
					if shouldDamage then
						harvestBlacklist[j] = {0, world.entityPosition(j), plantName, "plant"}
						world.damageTiles({world.entityPosition(j)}, "foreground", world.entityPosition(j), "plantish", 40, 1)
					else
						harvestBlacklist[j] = {0, world.entityPosition(j), plantName, false}
					end
				end    
		end
	else
		addLine("till", {armPos, toPointer})
		if blockCheck[1] ~= nil then
			for x = -1, 1 do
				for y = -1, 1 do
					local modBlock = vec2.add(blockCheck[1], {x,y})
					if world.material(modBlock, "foreground") and (world.mod(modBlock, "foreground") == nil or canRemoveMod(world.mod(modBlock, "foreground"))) and world.material(vec2.add(modBlock, {0,1}), "foreground") == false and root.materialConfig(world.material(modBlock, "foreground")) and root.assetJson(root.materialConfig(world.material(modBlock, "foreground"))).soil then
						world.placeMod(modBlock, "foreground", "tilled", nil, true)
						animator.playSound("till")
						world.damageTiles({blockCheck[1]}, "background", vec2.add(blockCheck[1], {0,1}), "plantish", 1, 1)
					end
				end
			end
		end
	end
	activeItem.setScriptedAnimationParameter("lineList", self.lines)
end

function lookForDrops(pos, name, radius)
	--sb.logInfo(tostring(pos).."|"..tostring(radius).."|"..tostring(self.owner).."|"..tostring(name))
	world.sendEntityMessage(self.scriptBug, "takeItems", pos, radius, self.owner, name)
	--world.callScriptedEntity(self.scriptBug, "takeItems", pos, radius, self.owner, name)
end
 
function canRemoveMod(modname)
	if removableMods[tostring(modname)] == true or string.find(modname, "grass") ~= nil or string.find(modname, "Grass") ~= nil then
		return true
	else
		return false
	end
end