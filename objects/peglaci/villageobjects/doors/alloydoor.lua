function init(args)
  entity.setColliding(true)
  if not self.initialized and not args then
	  self.initialized = true
	  if orientation == nil then
	    self.anchor = entity.configParameter("anchors")[1]
		if self.anchor == "left" then
		  entity.setAnimationState("doorState", "close" .. "Floor")
		elseif self.anchor == "right" then
		  entity.setAnimationState("doorState", "close" .. "Floor")
		elseif self.anchor == "top" then
		  entity.setAnimationState("doorState", "close" .. "Wall")
		elseif self.anchor == "bottom" then
		  entity.setAnimationState("doorState", "close" .. "Wall")
		end
	  end
  end

  if isDoorClosed() then
    entity.setColliding(true)
    entity.setAllOutboundNodes(true)
  else
    entity.setColliding(false)
    entity.setAllOutboundNodes(false)
  end

  onNodeConnectionChange()
end

function onNodeConnectionChange(args)
  entity.setInteractive(not entity.isInboundNodeConnected(0))
  if entity.isInboundNodeConnected(0) then
    onInboundNodeChange({ level = entity.getInboundNodeLevel(0) })
  end
end

function onInboundNodeChange(args)
  if args.level then
    openDoor()
  else
    closeDoor()
  end
end

function onInteraction(args)
  if (entity.isInboundNodeConnected(0)) then
    return
  end
  if isDoorClosed() then
    openDoor(args.source[1])
  else
    closeDoor()
  end
end

function hasCapability(capability)
  if (entity.isInboundNodeConnected(0)) then
    return
  end
  if capability == 'door' then
    return true
  elseif capability == 'closeFloor' or capability == 'closeWall' then
    return isDoorClosed()
  else
    return false
  end
end

function isDoorClosed()
  return entity.animationState("doorState") == "closeWall" or entity.animationState("doorState") == "closeFloor"
end

--function doorDirection()
--  return (entity.animationState("doorState") == "closeLeft" or entity.animationState("doorState") == "openLeft") and -entity.direction() or entity.direction()
--end

function closeDoor()
  if not isDoorClosed() then
    if entity.animationState("doorState") == "openWall" then
      entity.setAnimationState("doorState", "closeWall")
    else
      entity.setAnimationState("doorState", "closeFloor")
    end
    entity.playSound("closeSounds")
    entity.setColliding(true)
    entity.setAllOutboundNodes(true)
  end
end

function openDoor()
  if isDoorClosed() then
    if entity.animationState("doorState") == "closeWall" then
      entity.setAnimationState("doorState", "openWall")
    else
      entity.setAnimationState("doorState", "openFloor")
    end
    entity.playSound("openSounds")
    entity.setColliding(false)
    entity.setAllOutboundNodes(false)
  end
end
