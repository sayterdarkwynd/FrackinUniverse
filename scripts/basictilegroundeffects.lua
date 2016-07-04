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
  sb.logInfo("groundMat: %s", groundMat)
  for i, effect in ipairs(groundMat[1]) do -- so multiple Ephemeral Effects possible from a tile
    sb.logInfo("looking at %s / %s", i, effect)
	sb.logInfo("self.matCheck[groundMat[1]] = %s", self.matCheck[groundMat[1]])
	 effect = self.matCheck[groundMat[1][i]]
	sb.logInfo("effect now %s", effect)
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
  				 --effect      Move  Run  Jump  Fric   Force Slide  Bounce  Softness
  ["mud"] = 	     		{{"fumudslow"},  0.8, 1,   1,   14,   101, 0.25,    0,  1.75},
  ["clay"] = 	    		{{"fuclayslow"}, 1,   1,   1,   14,   101,    0,    0,  1.75},
  ["sand"] = 	    		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9},
  ["rainbowsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.2},
  ["glowingsand"] = 		{{"glow"},       1,   1,   1,   14,   101,    0.5,  0,  1.2} ,
  ["crystalsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,    0.5,  0,  1.9},
  ["glasssand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9},
  ["redsand"] = 		{{"jungleslow"}, 1,   1,   1,   14,   101,  0.5,    0,  1.9},
  ["jungledirt2"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1},
  ["swampdirtff"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1},
  ["springvines"] = 		{{"jungleslow"}, 1,   1,   1,   14,   100,  0.0,    0,  1},
  ["frozenwater"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1},
  ["ice"] = 			{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1},
  ["iceblock1"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1},
  ["iceblock2"] = 		{{"iceslip"},    1,   1,   1,   14,   100,  0.0,    0,  1},
  ["iceblock3"] = 		{{"iceslip3"},   1,   1,   1,   14,   101,  1.0,    0,  1.2},
  ["iceblock4"] = 		{{"iceslip2"},   1,   1,   1,   14,   101,  1.0,    0,  1.2},
  ["snow"] = 			{{"snowslow"},   1,   1,   1,   14,   100,  0.0,    0,  1},
  ["slush"] = 			{{"slushslow"},  1,   1,   1,   14,   100,  0.0,    0,  1},
  ["slime"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75},
  ["slime2"] = 			{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75},
  ["jellyblock"] = 		{{"slimestick"}, 1,   1,   1,   14,   101,  1.0,    1,  1.75},
  ["jellystone"] = 		{{"jumpboost15"},1,   1,   1,   14,   100,  0.0,    1,  1},
  ["blackslime"] =    {{"slimestick","weakpoison"}, 1,   1,   1,   14,   101,  1.5,    0,  1.65},
  ["spidersilkblock"] = 	{{"webstick"},   1,   1,   1,   14,   101,  0.0,    0,  1.32},
  ["irradiatedtile"] = 	      {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1},
  ["irradiatedtile2"] =       {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1},
  ["irradiatedtile3"] =          {{"radiationburn"},1,   1,   1,   14,   100,  0.0,    0,  1},
  ["protorock"] = 	         {{"ffextremeradiation"},1,   1,   1,   14,   100,  0.0,    0,  1.3},
  ["bioblock"] = 	          {{"regenerationblock"},1,   1,   1,   14,   100,  0.0,    0,  1.1},
  ["bioblock2"] = 	          {{"regenerationblock"},1,   1,   1,   14,   100,  0.0,    0,  1.2},
  ["biodirt"] = 	          {{"regenerationblock"},1,   1,   1,   14,   101,  1.0,    0,  1.85},
  ["metallic"] = 	          {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.3},
  ["asphalt"] = 	          {{"metalspeed"},1,   1,   1,   14,   100,  0.0,    0,  1.4},
  ["cloudblock"] = 	            {{"lowgrav"},1,   1,   1,   14,   101,  1.0,    0,  1.2},
  ["raincloud"] = 	                    {{"lowgrav"},1,   1,   1,   14,   101,  1.0,    0,  1.2},
  ["honeycombmaterial"] =            {{"honeyslow"},1,   1,   1,   14,   101,  0.0,    0,  1.7},
  ["speedblock"] = 		 {{"runboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75},
  ["jumpblock"] = 		        {{"jumpboost35"},1,   1,   1,   14,   101,  0.0,    0,  1.75}, 
  ["moltensteel"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75},
  ["moltentile"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75}, 
  ["moltensand"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75}, 
  ["moltenmetal"] = 		    {{"burning"},1,   1,   1,   14,   101,  0.0,    0,  1.75}, 
  ["magmatile"] = 		            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1},
  ["magmatile2"] = 		    {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1},
  ["redhotcobblestone"] = 	            {{"burning"},1,   1,   1,   14,   100,  0.0,    0,  1},  
  ["fublueslimedirt"] =   {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1},
  ["fublueslime"] = 	{{"regenerationblock","slimestick"},1,1,1,14,100,0.0,1,1.1},
 ["fublueslimestone"] = {{"regenerationblock","slimestick"},1,1,1,14,100,0.0,0.5,1.1}  

  }
end