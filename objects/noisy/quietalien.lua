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
    self.random = math.random(1,3)
    if self.random == 1 then
      world.spawnItem("wrappedbodyalien", object.position(), 1)
      object.smash(true)
    elseif self.random == 2 then
      world.spawnItem("wrappedbody", object.position(), 1)
      object.smash(true)
    elseif self.random == 3 then
      world.spawnItem("wrappedbodyputrid", object.position(), 1)
      object.smash(true)
    end
end