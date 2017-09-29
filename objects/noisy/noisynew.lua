function init()
  self.count = 0
  self.sounds = config.getParameter("sounds", {})
  animator.setSoundPool("noise", self.sounds)
  object.setInteractive(true)
end

function onInteraction()
  if self.count < 3 then
	  if #self.sounds > 0 then
	    animator.playSound("noise")
	    self.count = self.count +1
	  end
  elseif self.count == 3 then
    local crewtype = "crewmemberLoveliusSmythe"
    local seed = math.random(255)
    local parameters = {}
    local crewrace = "human"
    self.count = self.count +1
    world.spawnNpc(object.position(), crewrace, crewtype, 1, seed, parameters)  
  end
end

function onNpcPlay(npcId)
  local interact = config.getParameter("npcToy.interactOnNpcPlayStart")
  if interact == nil or interact ~= false then
    onInteraction()
  end
end
