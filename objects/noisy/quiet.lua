function init()
  self.random = math.random(1,2)	--50% can produce a corpse
  object.setInteractive(true)
end

function onInteraction()
  if self.random == 1 then  		--if random chance is 1
    self.random = 2 			-- set to 0 so we never repeat
    checkSarco()  			-- spawn the item
  end
end

function onNpcPlay(npcId)
  local interact = config.getParameter("npcToy.interactOnNpcPlayStart")
  if interact == nil or interact ~= false then
    onInteraction()
  end
end

function checkSarco()
      world.spawnItem("wrappedbodybirb", object.position(), 1)
      object.smash(true)
end
