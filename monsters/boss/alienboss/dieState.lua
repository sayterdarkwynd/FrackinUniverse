dieState = {}

function dieState.enterWith(args)
  if not args.die then return nil end

  return {
    timer = 1.0
  }
end

function dieState.enteringState(stateData)

  local players = world.players()
  for _,playerId in pairs(players) do
    world.sendEntityMessage(playerId, "shockhopperDeath")
  end
end

function dieState.update(dt, stateData)
  if stateData.timer <= 0.0 then
    self.dead = true
  end

  stateData.timer = stateData.timer - dt
  return false
end
