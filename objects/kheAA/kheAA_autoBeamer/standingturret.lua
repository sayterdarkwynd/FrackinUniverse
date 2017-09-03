require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"
require "/scripts/epoch.lua"

isTheDate=false

function init()
	checkIsTheDate()
  -- Positions and angles
  	--[[removableMods = {
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
	}]]--
  self.baseOffset = config.getParameter("baseOffset")
  self.basePosition = vec2.add(object.position(), self.baseOffset)
  self.tipOffset = config.getParameter("tipOffset") --This is offset from BASE position, not object origin

  self.offAngle = util.toRadians(config.getParameter("offAngle", -30))

  -- Targeting
  self.targetQueryRange = config.getParameter("targetQueryRange",4)

  -- Initialize turret
  object.setInteractive(false)

  self.state = FSM:new()
  self.state:set(offState)
end

function update(dt)
	if not deltaCheckDate or deltaCheckDate > 60 then
		deltaCheckDate=0
		checkIsTheDate()
	else
		deltaCheckDate=deltaCheckDate+dt
	end
	self.state:update(dt)

	world.debugPoint(firePosition(), "green")
end

--
-- States

function offState()
  animator.setAnimationState("attack", "dead")
  animator.playSound("powerDown")
  object.setAllOutputNodes(false)

  while true do
    animator.rotateGroup("gun", self.offAngle)

    if active() then break end
    coroutine.yield()
  end

  animator.playSound("powerUp")

  self.state:set(scanState)
end

function scanState()
  animator.setAnimationState("attack", "idle")
  util.wait(0.5)
  animator.playSound("scan")
  object.setAllOutputNodes(false)

  local timer = 0

  local scan = coroutine.wrap(function()
    while true do
		animator.rotateGroup("gun", self.offAngle)
      local target = findTarget()
      if target then return self.state:set(fireState, target) end
      util.wait(1.0)
    end
  end)

  while true do

    scan()

    if not active() then break end
    coroutine.yield()
  end

  self.state:set(offState)
end

function fireState(targetId)
  animator.setAnimationState("attack", "attack")
  animator.playSound("foundTarget")
  object.setAllOutputNodes(true)

  local maxFireAngle = util.toRadians(config.getParameter("maxFireAngle"))
  local fire = coroutine.wrap(autoFire)

  while true do
    if not active() then return self.state:set(offState) end

    if not world.entityExists(targetId) then break end
	if not validTarget(targetId) then break end
    local targetPosition = world.entityPosition(targetId)
    local toTarget = world.distance(targetPosition, self.basePosition)
    local targetDistance = world.magnitude(toTarget)
    local targetAngle = math.atan(toTarget[2], object.direction() * toTarget[1])

    if targetDistance > (self.targetQueryRange+4) or targetDistance < 2.5 or world.lineTileCollision(self.basePosition, targetPosition) then break end
    if math.abs(targetAngle) > util.toRadians(360) then break end

    animator.rotateGroup("gun", targetAngle)

    local rotation = animator.currentRotationAngle("gun")
    if math.abs(util.angleDiff(targetAngle, rotation)) < maxFireAngle then
      fire(targetId)
    end
    coroutine.yield()
  end

  util.wait(1.0)

  self.state:set(scanState)
end

--
-- Helping functions, not states

function active()
  if object.isInputNodeConnected(0) then
    return object.getInputNodeLevel(0)
  end

  storage.active = storage.active ~= nil and storage.active or true
  return storage.active
end

function firePosition()
  local animationPosition = vec2.div(config.getParameter("animationPosition"), 8)
  local fireOffset = vec2.add(animationPosition, animator.partPoint("gun", "projectileSource"))
  return vec2.add(object.position(), fireOffset)
end

-- Coroutine
function autoFire(target)
	local rotation = animator.currentRotationAngle("gun")
	local aimVector = {object.direction() * math.cos(rotation), math.sin(rotation)}
	while true do
		if world.entityType(target)=="player" then
			world.sendEntityMessage(target,"applyStatusEffect","nude")
		else
			world.damageTiles({world.entityPosition(target)}, "foreground", world.entityPosition(target), "plantish", 0.2, 1)
		end
		animator.playSound("fire")
		util.wait(config.getParameter("fireTime",0.1))
	end
end

-- Coroutine
function findTarget()
	local nearEntities = world.entityQuery(self.basePosition, self.targetQueryRange,{includedTypes={"plant","object"}})
	if isTheDate then
		local bumper=world.entityQuery(self.basePosition, self.targetQueryRange,{includedTypes={"player","npc"}})
		for _,a in pairs(bumper) do
			table.insert(nearEntities,a)
		end
	end
	--sb.logInfo("%s",{nearEntities=nearEntities})
	return util.find(nearEntities,
		function(entityId)
			local targetPosition = world.entityPosition(entityId)
			if world.lineTileCollision(self.basePosition, targetPosition) then
				return false
			end
			
			local toTarget = world.distance(targetPosition, self.basePosition)
			local targetAngle = math.atan(toTarget[2], object.direction() * toTarget[1])
			if not ( world.magnitude(toTarget) > 2.5 and math.abs(targetAngle) < util.toRadians(360) ) then
				return false
			end
			
			local eType=world.entityType(entityId)
			
			if eType == "plant" or eType =="player" or eType =="npc" then
				return true
			end
			
			local tStage=world.farmableStage(entityId)
			if tStage ~= nil then
				--sb.logInfo("Stage:"..tStage)
				stages=world.getObjectParameter(entityId,"stages")
				--sb.logInfo(sb.printJson(stages))
				if stages ~= nil then
					if stages[tStage+1].harvestPool ~= nil then
						return true
					end
				end
			end
			return false
		end
	)
end

function validTarget(entityId)
	local targetPosition = world.entityPosition(entityId)
	if world.lineTileCollision(self.basePosition, targetPosition) then
		return false
	end
	
	local toTarget = world.distance(targetPosition, self.basePosition)
	local targetAngle = math.atan(toTarget[2], object.direction() * toTarget[1])
	if not ( world.magnitude(toTarget) > 2.5 and math.abs(targetAngle) < util.toRadians(360) ) then
		return false
	end
	
	local eType=world.entityType(entityId)
	
	if eType == "plant" or eType =="player" or eType =="npc" then
		return true
	end
	
	local tStage=world.farmableStage(entityId)
	if tStage ~= nil then
		--sb.logInfo("Stage:"..tStage)
		stages=world.getObjectParameter(entityId,"stages")
		--sb.logInfo(sb.printJson(stages))
		if stages ~= nil then
			if stages[tStage+1].harvestPool ~= nil then
				return true
			end
		end
	end
	return false
end

function checkIsTheDate()
	local epoDat=epoch.currentToTable()
	if epoDat.day==1 and epoDat.month==4 then
		isTheDate=true
	else
		isTheDate=false
	end
end