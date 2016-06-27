recoverSpecial = {}

function recoverSpecial.enter()
  if self.skillCooldownTimers["recoverSpecial"] <= 0 then
    local healthFraction = entity.health() / entity.maxHealth()
    if healthFraction <= entity.configParameter("recoverSpecial.triggerHealthFraction") then
      return { healthPerSecond = (entity.maxHealth() * entity.configParameter("recoverSpecial.recoverHealthFraction")) / entity.configParameter("recoverSpecial.skillTimeLimit") }
    end
  end

  return nil
end

function recoverSpecial.enterWith(args)
  if not args.recoverSpecial then return nil end

  return { healthPerSecond = (entity.maxHealth() * entity.configParameter("recoverSpecial.recoverHealthFraction")) / entity.configParameter("recoverSpecial.skillTimeLimit") }
end

function recoverSpecial.enteringState(stateData)
  setAggressive(true, false)
  
  entity.setAnimationState("movement", "idle")
  entity.setAnimationState("attack", "idle")
  entity.setActiveSkillName("recoverSpecial")

  entity.setEffectActive("recover", true) 
end

function recoverSpecial.update(dt, stateData)
  if not canContinueSkill() or entity.health() <= 0 then return true end

  entity.heal(stateData.healthPerSecond * script.updateDt())

  return false
end

function recoverSpecial.leavingState(stateData)
  entity.setEffectActive("recover", false)
end
