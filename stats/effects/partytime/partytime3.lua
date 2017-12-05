function init()
  status.removeEphemeralEffect("partytime5")
  status.removeEphemeralEffect("partytime4")
  status.removeEphemeralEffect("partytime2")
  self.timers = {}
  for i = 1, 4 do
    self.timers[i] = math.random() * 2 * math.pi
  end
  script.setUpdateDelta(3)
  self.timerColor = 1
  self.songTimer = 0
  self.varColorMain = math.random(1,5)
end

function update(dt)
  if entity.entityType("monster") or entity.entityType("npc") then
      self.randScream = math.random(1000)
	  if self.randScream >= 999 then
	     if entity.entityType("monster") then monster.say("PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARTY!!!!!") end
	     if entity.entityType("npc") then npc.say("PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARTY!!!!!") end
	  elseif self.randScream >= 998 then
	     if entity.entityType("monster") then monster.say("WOOOOOOOOOOOOOOO THIS IS AWESOME!!!") end
	     if entity.entityType("npc") then npc.say("WOOOOOOOOOOOOOOO THIS IS AWESOME!!!") end
	  elseif self.randScream >= 997 then
	     if entity.entityType("monster") then monster.say("WHY THE HELL AM I SCREECHING SO LOUDLY?") end
	     if entity.entityType("npc") then npc.say("I MAY HAVE JUST SOILED MYSELF IN MY OVEREXUBERANT EXCITEMENT.") end
	  elseif self.randScream >= 996 then
	     if entity.entityType("monster") then monster.say("HEY, WANT A LIGHT SHOW?!?!?!") end
	     if entity.entityType("npc") then npc.say("HEY, WANT A LIGHT SHOW?!?!?!") end
	  end
  end
  
  if (self.songTimer)< 0 then
    self.songTimer=1
  end
  
  if (self.songTimer)< 1 then
    animator.playSound("dancemusic")
    self.songTimer = 11.07
  end 

  self.varColorMain = math.random(1,5)
  if self.timerColor == 0 then
    if self.varColorMain == 1 then
      effect.setParentDirectives(string.format("fade=00bb00=%.1f", self.varColorMain * 0.1))
    elseif self.varColorMain == 2 then
      effect.setParentDirectives(string.format("fade=ffea00=%.1f", self.varColorMain * 0.1))
    elseif self.varColorMain == 3 then
      effect.setParentDirectives(string.format("fade=ceffae=%.1f", self.varColorMain * 0.1))
    elseif self.varColorMain == 4 then
      effect.setParentDirectives(string.format("fade=aecfea=%.1f", self.varColorMain * 0.1))
    elseif self.varColorMain == 5 then
      effect.setParentDirectives(string.format("fade=55faba=%.1f", self.varColorMain * 0.1))
    end
    self.timerColor = 15
  end
  
  self.timerColor = self.timerColor - 1
  self.songTimer = self.songTimer - dt

  for i = 1, 4 do
    self.timers[i] = self.timers[i] + dt
    if self.timers[i] > (2 * math.pi) then 
      self.timers[i] = self.timers[i] - 2 * math.pi 
    end
    
    local lightAngle = math.cos(self.timers[i]) * 120 + (i * 90)
    animator.setLightPointAngle("light"..i, lightAngle)
  end
  
end

function uninit()
  animator.stopAllSounds("dancemusic")
end