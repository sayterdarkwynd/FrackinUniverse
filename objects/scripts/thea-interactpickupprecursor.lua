function init()
  if storage.itemHasSpawned == false or storage.itemHasSpawned == nil then
    object.setInteractive(true)
    animator.setAnimationState("interactiveObject", "filled")
	storage.itemHasSpawned = false
  else
    animator.setAnimationState("interactiveObject", "empty")
	object.setInteractive(false)
  end
  
  self.spawnableItem = config.getParameter("spawnableItem")
end

function open()
  animator.setAnimationState("interactiveObject", "empty")
  world.spawnItem(self.spawnableItem, entity.position(), 1)
  storage.itemHasSpawned = true
  object.setInteractive(false)
  
  --Make sure that, if the object is broken after having been collected, nothing drops
  object.setConfigParameter("breakDropPool", "empty")
  player.enableTech("microsphereprecursor")
end

function onInteraction(args)
  if storage.itemHasSpawned == false then
    open()
  end
end

function update(dt) 
  
end
