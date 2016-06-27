local tileEffects_Init = init
local tileEffects_Update = update

function init()
  tileMaterials()
  self.airJumpModifier = 1
  tileEffects_Init() -- old Init()
end

function update(dt)
  if not mcontroller.onGround() and self.airJumpModifier ~= 1 then
    mcontroller.controlModifiers({airJumpModifier = self.airJumpModifier})
  end
  local groundSoftness = 1    
  if mcontroller.onGround() then
    self.airJumpModifier = 1
    groundMat = groundContact()
    if self.matCheck[groundMat] then
      applyTileEffects(self.matCheck[groundMat])
      groundSoftness = self.matCheck[groundMat][9]
    end
  end

  --reworked fall damage check to apply groundSoftness
  local minimumFallDistance = 14
  local fallDistanceDamageFactor = 3
  local minimumFallVel = 40
  local baseGravity = 80
  local gravityDiffFactor = 1 / 30.0

  local curYVelocity = mcontroller.yVelocity()

  local yVelChange = curYVelocity - self.lastYVelocity
  if self.fallDistance > minimumFallDistance and yVelChange > minimumFallVel  and mcontroller.onGround() then
    local damage = (self.fallDistance - minimumFallDistance) * fallDistanceDamageFactor * groundSoftness
    damage = damage * (1.0 + (world.gravity(mcontroller.position()) - baseGravity) * gravityDiffFactor)
    damage = damage * status.stat("fallDamageMultiplier")
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = damage,
        damageSourceKind = "falling",
        sourceEntityId = entity.id()
      })
    -- set self.fallDistance to 0 to prevent normal fall damage check from triggering additional damage
    self.fallDistance = 0
  end
  
  tileEffects_Update(dt) -- old update()
end

function applyTileEffects(groundMat)
  for i, effect in ipairs(groundMat[1]) do -- so multiple Ephemeral Effects possible from a tile
    status.addEphemeralEffects{{effect = self.matCheck[groundMat][1][i]}}
  end
  mcontroller.controlModifiers({
      groundMovementModifier = groundMat[2],
      runModifier = groundMat[3],
      airJumpModifier = groundMat[4]
    })
  mcontroller.controlParameters({
      normalGroundFriction = groundMat[5],
      groundForce = groundMat[6],
      slopeSlidingFactor = groundMat[7],
      bounceFactor = groundMat[8]
    })
  if groundMat[4] ~= 1 then
    self.airJumpModifier = groundMat[4]
  end
end

function groundContact()
  local mpos = mcontroller.position()
  local position = {mpos[1],math.floor(mpos[2])}
  local groundMat = world.material(vec2.add({position[1],position[2]}, {0,-3}), "foreground")
  world.debugLine(position, {position[1], position[2]-3}, "green")
  if groundMat == false then
    if math.ceil(mpos[1]-0.5) == math.floor(mpos[1]) then
      groundMat = world.material(vec2.add(position, {-1,-3}), "foreground")
      world.debugLine(position, {position[1]-1, position[2]-3}, "green")
    else
      groundMat = world.material(vec2.add(position, {1,-3}), "foreground")
      world.debugLine(position, {position[1]+1, position[2]-3}, "green")
    end
  end
  if groundMat == false then
    local stoodOnObject = world.objectQuery(vec2.add({position[1],position[2]}, {0,-3.5}), 0.1, {order = "nearest"})
    if stoodOnObject == false then
      if math.ceil(mpos[1]-0.5) == math.floor(mpos[1]) then
        stoodOnObject = world.objectQuery(vec2.add(position, {-1,-3.5}), 0.1, {order = "nearest"})
      else
        stoodOnObject = world.objectQuery(vec2.add(position, {1,-3.5}), 0.1, {order = "nearest"})
      end
    end
    if #stoodOnObject >= 1 then
      stoodOn = tostring(world.entityName(stoodOnObject[1]))
      world.debugText(stoodOn,{position[1]-(string.len(stoodOn)*0.25),position[2]-3.5},"green")
    end
  else
    world.debugText(tostring(groundMat),{position[1]-(string.len(tostring(groundMat))*0.25),position[2]-3.5},"green")
  end
  return groundMat,stoodOn or false
end

function tileMaterials()
  -- ["materialName"] = {{EphemeralEffect Stats to apply},
  --  groundMovementModifier, runModifier, JumpModifier,                    <-- mcontroller.controlModifiers
  --  normalGroundFriction, groundForce, slopeSlidingFactor, bounceFactor,  <-- mcontroller.controlParameters 
  --  groundSoftness}
  --                      {EF},gMM, rM,  JM,  nGF,  gF,  sSF, bF,  gS
  -- ["anormaltile"] =    {{}, 1,   1,   1,   14.0, 101, 0.0, 0,   1  }
  self.matCheck = { 
      ["cloudblock"] = {{},1,1,1,14,100,0,1},
    ["mud"] = {{},1,1,1,14,100,0,1},
    ["clay"] = {{},1,1,1,14,100,0,1},
    ["sewage"] = {{},1,1,1,14,100,0,1},
    ["tar"] = {{},1,1,1,14,100,0,1},
    ["frozenwater"] = {{},1,1,1,0.25,10,0.25,1},
    ["ice"] = {{},1,1,1,0.5,10,0.5,1},
    --["iceblock"] = {{},1,1,1,0.5,10,0.5,1},
    ["slime"] = {{},1,1,1,14,100,0,1},
    ["slush"] = {{},1,1,1,14,100,0,1},
    ["snow"] = {{},1,1,1,14,100,0,1},
    ["spidersilkblock"] = {{},1,1,1,14,100,0,1},  

  }
end