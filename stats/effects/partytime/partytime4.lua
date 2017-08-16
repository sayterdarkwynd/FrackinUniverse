function init()
  status.removeEphemeralEffect("partytime3")
  status.removeEphemeralEffect("partytime2")
  self.timers = {}
  for i = 1, 4 do
    self.timers[i] = math.random() * 2 * math.pi
  end
  script.setUpdateDelta(3)
  self.timerColor = 1
  self.songTimer = 0
end

function update(dt)
  if (self.songTimer)< 0 then
    self.songTimer=1
  end
  
  if (self.songTimer)<1 then
    animator.playSound("dancemusic")
    self.songTimer = 24.2
  end 

  self.songTimer = self.songTimer - dt

end

function uninit()
  animator.stopAllSounds("dancemusic")

end