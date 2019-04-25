function init()
  self.boostFuel = status.statusProperty("boostFuel") or 0
  self.lastJump = false
  self.lastBoost = nil
end

function input(args)
  local currentJump = args.moves["jump"]
  local currentBoost = nil

  if not mcontroller.onGround() then
    if not mcontroller.canJump() and currentJump and not self.lastJump then
      if args.moves["right"] and args.moves["up"] then
        currentBoost = "boostRightUp"
      elseif args.moves["right"] and args.moves["down"] then
        currentBoost = "boostRightDown"
      elseif args.moves["left"] and args.moves["up"] then
        currentBoost = "boostLeftUp"
      elseif args.moves["left"] and args.moves["down"] then
        currentBoost = "boostLeftDown"
      elseif args.moves["right"] then
        currentBoost = "boostRight"
      elseif args.moves["down"] then
        currentBoost = "boostDown"
      elseif args.moves["left"] then
        currentBoost = "boostLeft"
      elseif args.moves["up"] then
        currentBoost = "boostUp"
      end
    elseif currentJump and self.lastBoost then
      currentBoost = self.lastBoost
    end
  end

  self.lastJump = currentJump
  self.lastBoost = currentBoost

  return currentBoost
end

function update(args)
  status.setStatusProperty("boostFuel", self.boostFuel)
  local action = input(args)
  local boostControlForce = config.getParameter("boostControlForce")
  local boostSpeed = config.getParameter("boostSpeed")

  if mcontroller.onGround() then
  self.boostFuel = 300
 end

  local diag = 1 / math.sqrt(2)
  local boostDirection = false

  if action == "boostRightUp" then
    boostDirection = {boostSpeed * diag, boostSpeed * diag}
  elseif action == "boostRightDown" then
    boostDirection = {boostSpeed * diag, -boostSpeed * diag}
  elseif action == "boostLeftUp" then
    boostDirection = {-boostSpeed * diag, boostSpeed * diag}
  elseif action == "boostLeftDown" then
    boostDirection = {-boostSpeed * diag, -boostSpeed * diag}
  elseif action == "boostRight" then
    boostDirection = {boostSpeed, 0}
  elseif action == "boostDown" then
    boostDirection = {0, -boostSpeed}
  elseif action == "boostLeft" then
    boostDirection = {-boostSpeed, 0}
  elseif action == "boostUp" then
    boostDirection = {0, boostSpeed}
  end
  
  if boostDirection and self.boostFuel > 0 then
    mcontroller.controlApproachVelocity(boostDirection, boostControlForce)
    self.boostFuel = self.boostFuel - 1
    animator.setFlipped(mcontroller.facingDirection() < 0)
    animator.setParticleEmitterActive("rocketParticles", true)
  else
    animator.setParticleEmitterActive("rocketParticles", false)
  end
end
