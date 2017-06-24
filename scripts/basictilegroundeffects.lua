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
  local softness = 1    
  if mcontroller.onGround() then
    self.airJumpModifier = 1
    local groundMat = groundContact()
    if self.matCheck[groundMat] then
      applyTileEffects(self.matCheck[groundMat])
      softness = self.matCheck[groundMat][9]
    end
  end

  --reworked falling to apply Softness and Brittle tiles
  local minimumFallDistance = 14
  local fallDistanceDamageFactor = 3
  local minimumFallVel = 40
  local baseGravity = 80
  local gravityDiffFactor = 1 / 30.0

  local curYVelocity = mcontroller.yVelocity()

  local yVelChange = curYVelocity - self.lastYVelocity
  
  -- check for brittle tiles and damage them
  if mcontroller.onGround() then brittleTiles(yVelChange,minimumFallVel) end
  
  -- falling damage
  if self.fallDistance > minimumFallDistance and yVelChange > minimumFallVel and mcontroller.onGround() then
    local damage = (self.fallDistance - minimumFallDistance) * fallDistanceDamageFactor * softness
    damage = damage * (1.0 + (world.gravity(mcontroller.position()) - baseGravity) * gravityDiffFactor)
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


function applyTileEffects(groundMat)
  -- sb.logInfo("groundMat: %s", groundMat)
  for i, effect in ipairs(groundMat[1]) do -- so multiple Ephemeral Effects possible from a tile
    -- sb.logInfo("looking at %s / %s", i, effect)
    status.addEphemeralEffects({effect})
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
  local groundMat = world.material(vec2.add({position[1],position[2]}, {0,-2.5}), "foreground")
  local offset = 0
  --world.debugLine({position[1], position[2]-1.5}, {position[1], position[2]-2.5}, "green")
  --local collision = world.collisionBlocksAlongLine(position,vec2.add({position[1],position[2]}, {0,-3},false,3))
  --world.debugText(table.dump(collision),{position[1]-(string.len(tostring(groundMat))*0.25),position[2]-5.5},"green")
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
  return groundMat, offset, stoodOn or false
end



function brittleTiles(yVelChange,minimumFallVel)
  local groundMat, offset = groundContact()
  if mcontroller.onGround() and self.matCheck[groundMat] then
    local brittle = self.matCheck[groundMat][10] or 0
    if brittle ~= 0 and self.fallDistance > brittle and yVelChange > minimumFallVel - brittle then
      local damage = math.random(self.matCheck[groundMat][11])+1
      local position = {mcontroller.position()[1],math.floor(mcontroller.position()[2])}
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
      world.spawnProjectile("invisibleprojectile", position, entity.id(), {0,0}, false, { timeToLive = 0,
          damageType = "noDamage", actionOnReap = {{ action = "sound", options = { self.matCheck[groundMat][12] } }}
        })
    end
  end
end


function tileMaterials()
  -- ["materialName"] = {{EphemeralEffect Stats to apply},
  --  groundMovementModifier, runModifier, JumpModifier,                    <-- mcontroller.controlModifiers
  --  normalGroundFriction, groundForce, slopeSlidingFactor, bounceFactor,  <-- mcontroller.controlParameters 
  --  groundSoftness}
  --                      {EF},gMM, rM,  JM,  nGF,  gF,  sSF, bF,  gS
  -- ["anormaltile"] =    {{}, 1,   1,   1,   14.0, 101, 0.0, 0,   1  }
  self.matCheck = { 
  				 --effect      Move  Run  Jump  Fric   Force Slide  Bounce  Softness
  ["mud"] = 	     		{{"fumudslow"},  0.8, 1,   1,   14,   101, 0.25,    0,  1.75, 1,3,"/sfx/blocks/footstep_ash.ogg"},
  ["clay"] = 	    		{{"fuclayslow"}, 1,   1,   1,   14,   101,    0,    0,  1.75, 1,4,"/sfx/blocks/footstep_ash.ogg"},
  ["sand"] = 	    		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9, 2,3,"/sfx/blocks/footstep_ash.ogg"},
  ["rainbowsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.2, 2,3,"/sfx/blocks/footstep_ash.ogg"},
  ["glowingsand"] = 		{{"glow"},       1,   1,   1,   14,   101,    0.5,  0,  1.2, 2,3,"/sfx/blocks/footstep_ash.ogg"},
  ["crystalsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9, 0},
  ["glasssand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9, 5, 5, "/sfx/blocks/footstep_ash.ogg"},
  ["redsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9, 0},
  ["jungledirt2"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1,   0},
  ["swampdirtff"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1,   0},
  ["springvines"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1,   0},
  ["frozenwater"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,  10, 3, "/sfx/objects/ice_break1.ogg"},
  ["glass"] =                   {{         },    1,   1,   1,   14,   101,  0.0,    0,  1,  10, 5, "/sfx/objects/prism_break_large2.ogg"},
  ["ice"] = 			{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,   3, 3, "/sfx/objects/ice_break1.ogg"},
  ["iceblock1"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,   3, 3, "/sfx/objects/ice_break1.ogg"},
  ["iceblock2"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1,   3, 3, "/sfx/objects/ice_break1.ogg"},
  ["iceblock3"] = 		{{"iceslip3"},   1,   1,   1,   14,   101,  1.0,    0,  1.2, 3, 3, "/sfx/objects/ice_break1.ogg"},
  ["iceblock4"] = 		{{"iceslip2"},   1,   1,   1,   14,   101,  1.0,    0,  1.2, 3, 3, "/sfx/objects/ice_break1.ogg"},
  ["snow"] = 			{{"snowslow"},   1,   1,   1,   14,   100,  0.0,    0,  1,   8, 3, "/sfx/blocks/footstep_ash.ogg"},
  ["slush"] = 			{{"slushslow"},  1,   1,   1,   14,   100,  0.0,    0,  1,   8, 3, "/sfx/blocks/footstep_ash.ogg"},
  ["slime"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0},
  ["slime2"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0},
  ["fujellyblock"] = 		{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0},
  ["jellyblock"] = 		{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75, 0},
  ["jellystone"] = 		{{"jumpboost15"},1,   1,   1,   14,   100,  0.0,    1,  1, 0},
  ["blackslime"] =  {{"slimestick","weakpoison"}, 1,   1,   1,   14,   101,  1.5,    0,  1.65, 0},
  ["spidersilkblock"] = 	{{"webstick"},   1,   1,   1,   14,   101,  0.0,    0,  1.32, 0},
  ["irradiatedtile"] = 	      {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1, 0},
  ["irradiatedtile2"] =       {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1, 0},
  ["irradiatedtile3"] =          {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1, 0},
  ["protorock"] =         {{"ffextremeradiation"},1,   1,   1,   14,   100,  0.0,    0,  1.3, 0},
  ["bioblock"] = 	          {{"fumudslow"},1,   1,   1,   14,   100,  0.0,    0,  1.1, 0},
  ["bioblock2"] =  {{"percentarmorboostnegproto"},1,   1,   1,   14,   100,  0.0,    0,  1.2, 0},
  ["metallic"] = 	          {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.3, 0},
  ["asphalt"] = 	          {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.4, 0},
  ["cloudblock"] = 	          {{"lowgrav"},1,   1,   1,   14,   101,  1.0,    0,  1.2,   10,10,"/sfx/blocks/footstep_ash.ogg"},
  ["raincloud"] = 	          {{"lowgrav"},1,   1,   1,   14,   101,  1.0,    0,  1.2,   10,10,"/sfx/blocks/footstep_ash.ogg"},
  ["honeycombmaterial"] =          {{"honeyslow"},1,   1,   1,   14,   101,  0.0,    0,  1.7, 0},
  ["speedblock"] = 		 {{"runboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0},
  ["jumpblock"] = 		{{"jumpboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0}, 
  ["moltensteel"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0},
  ["moltentile"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0}, 
  ["moltensand"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0}, 
  ["moltenmetal"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75, 0}, 
  ["magmatile"] = 		            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1, 0},
  ["magmatile2"] = 		    {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1, 0},
  ["redhotcobblestone"] = 	            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1, 0},  
  ["fublueslimedirt"] =             {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1, 2,2,"/sfx/blocks/footstep_ash.ogg"},
  ["fublueslime"] = 	            {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1, 2,2,"/sfx/blocks/footstep_ash.ogg"},
  ["fublueslimestone"] =          {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,0.5,1.1, 2,2,"/sfx/blocks/footstep_ash.ogg"}  

  }
end