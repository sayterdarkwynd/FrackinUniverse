rushAttack = {}

function rushAttack.enter()
  if not canStartSkill("rushAttack") then return nil end

  return { rushMovement = util.toDirection(self.toTarget[1]) }
end

function rushAttack.enteringState(stateData)
  setAggressive(true, true)

  monster.setActiveSkillName("rushAttack")
end

function rushAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  if isBlocked() and not stateData.didFlip then
    stateData.rushMovement = -stateData.rushMovement
    stateData.didFlip = true
  end

  moveX(stateData.rushMovement)

  return false
end
