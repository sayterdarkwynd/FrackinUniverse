init = function()
  storage.familiarTranitions = {
    "owltofrog",
    "frogtocat",
    "cattoowl"
  }
  storage.stage = storage.stage or 1
  storage.maxStage = #storage.familiarTranitions
  storage.interactTimer = 3
  object.setInteractive(true)
end

onInteraction = function(args)
  if storage.interactTimer > 0 then
    return nil
  end

  local whatTransition = storage.familiarTranitions[storage.stage]

  animator.setAnimationState("familiarState", whatTransition, true)
  storage.interactTimer = 3.0

  storage.stage = storage.stage + 1
  if storage.stage > storage.maxStage then
    storage.stage = 1
  end
end

update = function(dt)
  storage.interactTimer = math.max(storage.interactTimer - dt, 0)
end
