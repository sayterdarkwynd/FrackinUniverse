local tileEffects_Init = init
local tileEffects_Update = update
local applyTileEffects
local groundContact
local brittleTiles

tileEffects = {}
currentTile = {}
collisionParams = {}


function init()
  tileMaterials()
  self.airJumpModifier = 1
  collisionParams = root.assetJson("/player.config:collisionParams")
  tileEffects_Init() -- old Init()
end


function update(dt)
  if mcontroller.isNullColliding() then
    --skip update when behind on loading chucks, plus there is nothing to collide with anyhow.
    return
  end

  local groundMat, offset, stoodOn
  local onGround = mcontroller.onGround()
  local softness = 1
  self.position = mcontroller.position()
  if not onGround and self.airJumpModifier ~= 1 then
    mcontroller.controlModifiers({airJumpModifier = self.airJumpModifier})
  end

  
  --reworked falling to apply Softness and Brittle tiles
  local minimumFallDistance = collisionParams.minimumFallDistance
  local fallDistanceDamageFactor = collisionParams.fallDistanceDamageFactor
  local minimumFallVel = collisionParams.minimumFallVel
  local baseGravity = collisionParams.baseGravity
  local gravityDiffFactor = collisionParams.gravityDiffFactor
  local curYVelocity = mcontroller.yVelocity()
  local yVelChange = curYVelocity - self.lastYVelocity

  if onGround then
    self.airJumpModifier = 1
    groundMat, offset, stoodOn = groundContact()

    if currentTile then
      applyTileEffects()
      --applyTileEffects(groundMat)
      softness = currentTile["softness"]
      --softness = self.matCheck[groundMat][9]
      -- check for brittle tiles and damage them
      brittleTiles(yVelChange, minimumFallVel, groundMat, offset)
    end
  end

  -- falling damage
  if self.fallDistance > minimumFallDistance and yVelChange > minimumFallVel and onGround then
    local damage = (self.fallDistance - minimumFallDistance) * fallDistanceDamageFactor * softness
    damage = damage * (1.0 + (world.gravity(self.position) - baseGravity) * gravityDiffFactor)
    damage = damage * status.stat("fallDamageMultiplier")
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = damage,
      damageSourceKind = "falling",
      sourceEntityId = entity.id()
    })
  -- set self.fallDistance to 0 to prevent old updates fall damage check from triggering additional falling damage
  self.fallDistance = 0
  end

  tileEffects_Update(dt) -- old update()
end


applyTileEffects = function(groundMat)
  
  status.addEphemeralEffects(currentTile["effects"])
  mcontroller.controlModifiers(currentTile["controlModifiers"])
  mcontroller.controlParameters(currentTile["controlParameters"])

  local airJumpModifier = currentTile.controlModifiers.airJumpModifier
  if airJumpModifier ~= 1 then
    self.airJumpModifier = airJumpModifier
  end
end


groundContact = function()
  local mpos = self.position
  local position = {mpos[1],math.floor(mpos[2])}
  local groundMat = world.material(vec2.add({position[1],position[2]}, {0,-2.5}), "foreground")
  local offset = 0

  if groundMat == false then
    if mpos[1] - math.floor(mpos[1]) < 0.5 then
      groundMat = world.material(vec2.add(position, {-1,-2.5}), "foreground")
      --world.debugLine({position[1], position[2]-1.5}, {position[1]-1, position[2]-2.5}, "green")
      offset = -1
    else
      groundMat = world.material(vec2.add(position, {1,-2.5}), "foreground")
      --world.debugLine({position[1], position[2]-1.5}, {position[1]+1, position[2]-2.5}, "green")
      offset = 1
    end
  end
  if groundMat == false then
    local stoodOnObject = world.objectQuery(vec2.add({position[1],position[2]}, {0,-2.5}), 0.1, {order = "nearest"})
    if stoodOnObject == false then
      if mpos[1] - math.floor(mpos[1]) < 0.5 then
        stoodOnObject = world.objectQuery(vec2.add(position, {-1,-2.5}), 0.1, {order = "nearest"})
        offset = -1
      else
        stoodOnObject = world.objectQuery(vec2.add(position, {1,-2.5}), 0.1, {order = "nearest"})
        offset = 1
      end
    end
    if #stoodOnObject >= 1 then
      stoodOn = tostring(world.entityName(stoodOnObject[1]))
      --world.debugText(stoodOn,{position[1]-(string.len(stoodOn)*0.25),position[2]-3.5},"green")
    end
  else
    --world.debugText(tostring(groundMat),{position[1]-(string.len(tostring(groundMat))*0.25),position[2]-3.5},"green")
  end

  currentTile = tileEffects[groundMat]
  return groundMat, offset, stoodOn or false
end


brittleTiles = function(yVelChange,minimumFallVel, groundMat, offset)
  --local groundMat, offset = groundContact()
  --if mcontroller.onGround() and self.matCheck[groundMat] then
    --local brittle = self.matCheck[groundMat][10] or 0
    
  --if currentTile then
    local brittle = currentTile["brittle"] or false

    if brittle and self.fallDistance > brittle and yVelChange > minimumFallVel - brittle then
      local damage = math.random(currentTile["damage"])+1
      local position = {self.position[1],math.floor(self.position[2])}
      world.damageTiles({vec2.add(position,{offset,-3})}, "foreground", position, "blockish", damage, 0)
      for y = -1, 0 do
        for x = -1, 1 do
          local tilePos = vec2.add({position[1]+x, position[2]+y}, {offset,-3})
          local tile = world.material(tilePos, "foreground")
          if not (x == 0 and y == 0) and type(tile) == "string" and tile == groundMat then
            world.damageTiles({tilePos}, "foreground", position, "blockish", math.random(0,damage), 0)
          end
        end
      end
      world.spawnProjectile("invisibleprojectile", position, entity.id(), {0,0}, false, {
        timeToLive = 0,
        damageType = "noDamage",
        actionOnReap = {
          {
            action = "sound",
            options = currentTile[options]
          }
        }
      })
    end
  --end
end


function tileMaterials()
  tileEffects = root.assetJson("/tileEffects.config:vanilla_tiles")
  tileEffects.__index = function() return false end
end
