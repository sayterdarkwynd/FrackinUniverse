require("/scripts/util.lua")
require("/scripts/bossgen/globalstateplanner.lua")
require("/scripts/bossgen/platforming.lua")
require("/scripts/vec2.lua")
require("/stagehands/bossplanner/bossabilities/bossabilities.lua")

function init()
  storage.seed = storage.seed or sb.makeRandomSource():randu64()
  storage.elementalType = config.getParameter("elementalType", storage.elementalType or util.randomFromList({"fire", "poison", "ice", "electric"}))

  if entity.uniqueId() == nil then
    stagehand.setUniqueId(sb.makeUuid())
  end

  local dungeonParts = root.assetJson(config.getParameter("dungeonParts"))

  local bossAbilities = {}
  for _,configPath in pairs(config.getParameter("bossAbilities")) do
    local ability = root.assetJson(configPath)
    bossAbilities[ability.name] = ability
    if ability.scripts then
      for _,script in pairs(ability.scripts) do
        require(script)
      end
    end
  end
  self.bossAbilities = bossAbilities

  local triggers = config.getParameter("triggers")
  local reactions = config.getParameter("triggerReactions")

  self.planner = createPlanner(dungeonParts, triggers, reactions, bossAbilities)

  local spaceConfig = {
    size = {8, 8},
    dimensions = {8, 4}
  }
  spaceConfig.origin = vec2.add(entity.position(), vec2.mul(vec2.mul(spaceConfig.dimensions, -0.5), spaceConfig.size))
  self.spaceConfig = spaceConfig
  if not storage.plan then
    local plan, state = generate(self.planner, spaceConfig)
    storage.plan = {}
    storage.state = {}
    function storePredicate(p)
      local s = {
        p.name
      }
      s[1] = p.negated and "!"..s[1] or s[1] -- prepend ! if negated
      for _,predicand in pairs(p.predicands) do
        table.insert(s, Predicand.value(predicand))
      end
      return s
    end
    for _,op in pairs(plan) do
      local storedOp = {}
      storedOp.name = op.name
      storedOp.preconditions = util.map(op:preconditions():terms(), storePredicate)
      storedOp.postconditions = util.map(op:postconditions():terms(), storePredicate)
      storedOp.statemodifiers = util.map(op:statemodifiers():terms(), storePredicate)
      table.insert(storage.plan, storedOp)
    end
    for _,term in pairs(state:terms()) do
      table.insert(storage.state, storePredicate(term))
    end

    if storage.plan then
      sb.logInfo("Generated plan:")
      for _,op in pairs(storage.plan) do
        sb.logInfo("---%s", op.name)
      end
    end

    storage.interactive = placeDungeonParts(storage.plan, dungeonParts, spaceConfig)
  end
  message.setHandler("isPlanner", function() return true end)
  message.setHandler("interact", function()
      for _,objectUid in pairs(storage.interactive) do
          world.sendEntityMessage(objectUid, "trigger")
      end
    end)

  local reactions = reactionHooks(reactions, storage.plan)
  message.setHandler("trigger", function(_,_, triggerId, triggerPosition)
    if reactions[triggerId] then
      reactions[triggerId](triggerPosition)
    end
  end)

  if not storage.bossDead then
    local parameters = bossParametersFromPlan(bossAbilities, storage.plan, storage.state, spaceConfig)
    storage.bossUid = storage.bossUid or sb.makeUuid()
    self.bossId = spawnBoss(parameters, storage.bossUid, storage.seed)
  end

  updateEndBossDoor()
end

function update()
  if not self.bossId or not world.entityExists(self.bossId) then
    storage.bossDead = true
    updateEndBossDoor()
  end
end

function uninit()
  if self.bossId and world.entityExists(self.bossId) then
    world.sendEntityMessage(self.bossId, "despawn")
  end
end

function updateEndBossDoor()
  if world.loadUniqueEntity("endbossdoor") and storage.bossDead then
    world.sendEntityMessage("endbossdoor", "openDoor")
  end
end

function generationTest(planCount)
  local ops = {}
  local tries = 0

  local minLength = 999
  local maxLength = 0
  local sumLength = 0
  for i = 1, planCount do
    local plan, _, planTries = generate(self.planner, self.spaceConfig)
    tries = tries + planTries
    local abilities = util.filter(plan, function(op) return self.bossAbilities[op.name] ~= nil end)
    if #abilities < minLength then minLength = #abilities end
    if #abilities > maxLength then maxLength = #abilities end
    sumLength = sumLength + #abilities

    for _,op in pairs(plan) do
      ops[op.name] = ops[op.name] and ops[op.name] + 1 or 1
    end
  end
  sb.logInfo("Test finished, %s plans generated. Average %s attempts per plan.", planCount, tries / planCount)
  sb.logInfo("Min plan length: %s", minLength)
  sb.logInfo("Max plan length: %s", maxLength)
  sb.logInfo("Avg plan length: %s", sumLength / planCount)
  sb.logInfo("Operation count:")
  ops = util.tableValues(util.mapWithKeys(ops, function(k, v) return {string.format("%s - %s", k, v), v} end))
  table.sort(ops, function(a, b) return a[2] > b[2] end)
  ops = util.map(ops, function(v) return v[1] end)
  for _,op in ipairs(ops) do
    sb.logInfo("  %s", op)
  end
end

function createPlanner(dungeonParts, triggers, reactions, bossAbilities)
  local planner = GlobalStatePlanner.new(config.getParameter("maxPlannerCost", 100))
  planner.debug = false

  planner:setConstants({
    MovingAbility = "MovingAbility",
    StaticAbility = "StaticAbility",
    CloseRange = "CloseRange",
    LongRange = "LongRange",

    PiercingVulnerability = "PiercingVulnerability",
    DamageVulnerability = "DamageVulnerability",

    CertainPosition = "CertainPosition",
    GuidedPosition = "GuidedPosition"
  })

  planner:addRelations({
    createRelation("Object"), -- an indication that an object exists, used as a limiter on object types
    createRelation("Placement"), -- a space that has had a dungeon part placed in it, prevents overlap
    createRelation("PlayerBuffed"),
    defineRelation("Move") { priority = 10 }, -- indicates that the player will be forced to move
    createRelation("Boss"),
    defineRelation("Ability") { priority = -10 },
    inclusiveSpacesRelation("BossIn", "Boss", 50),
    createRelation("BossDanger"),
    defineRelation("Vulnerability") { priority = 100 },
    createRelation("WeaponEquipped")
  })

  planner:addRelations(PlatformingRelations)
  planner:addOperators(PlatformingOperators)

  planner:addOperators(config.getParameter("operators", {}))

  addPlannerDungeonParts(planner, dungeonParts)
  addPlannerTriggers(planner, triggers, reactions)
  addPlannerBossAbilities(planner, bossAbilities)

  return planner
end

function generate(planner, spaceConfig)
  local plan, state
  local tries = 0
  local maxTries = 100
  repeat
    if tries == maxTries - 1 then
      planner.debug = true -- try to get a hint at why the planning is failing
    end
    local initialState = {
      {"Ability", "anyType"}
    }
    local goalState = {
      {"Ability", "anyType"},
      {"DangerIn", {{0, 0}, {1, 0}, {2, 0}, {3, 0}, {4, 0}, {5, 0}, {6, 0}, {7, 0}}},
      {"Ability", "LongRange"},
      {"Ability", "CloseRange"}
    }
    if math.random() < config.getParameter("vulnerabilityChance", 1.0) then
      table.insert(goalState, {"Vulnerability", "vuln"})
    end
    local globalState = {
      {"Floor", 0, 0},
      {"Floor", 1, 0},
      {"Floor", 2, 0},
      {"Floor", 3, 0},
      {"Floor", 4, 0},
      {"Floor", 5, 0},
      {"Floor", 6, 0},
      {"Floor", 7, 0}
    }
    util.appendLists(initialState, globalState)

    plan, state = generatePlan(planner, planner:parseConjunction(initialState), planner:parseConjunction(goalState), planner:parseConjunction(globalState))
    planner:clearVariables()
    tries = tries + 1
  until plan or tries >= maxTries
  if not plan then
    error("Failed to generate plan after many attempts")
  end

  sb.logInfo("Generated plan after %s tries", tries)

  return plan, state, tries
end

-- adds dungeon pieces to the planner
function addPlannerDungeonParts(planner, dungeonParts)
  local operators = {}
  for name,part in pairs(dungeonParts) do
    local op = part.operator or {
      preconditions = {},
      postconditions = {},
      statemodifiers = {}
    }
    if part.floorSpaces then
      table.insert(op.preconditions, {"ReachableIn", part.floorSpaces})
      for _,offset in pairs(part.floorSpaces) do
        table.insert(op.preconditions, {"!Floor", offset[1], offset[2]})
        table.insert(op.statemodifiers, {"Floor", offset[1], offset[2]})
      end
    end
    local spaces = {}
    for _,piece in pairs(part.pieces or {}) do
      if not contains(spaces, piece.offset) then
        table.insert(spaces, piece.offset)
      end
    end
    for _,object in pairs(part.objects or {}) do
      if not contains(spaces, object.space) then
        table.insert(spaces, object.space)
      end
    end
    for _,space in pairs(spaces) do
      table.insert(op.preconditions, {"!Placement", space[1], space[2]})
      table.insert(op.statemodifiers, {"Placement", space[1], space[2]})
    end
    operators[name] = op
  end
  planner:addOperators(operators)
end

-- adds triggers and reaction operators to the planner
-- sets up callbacks
function addPlannerTriggers(planner, triggers, reactions)
  local nextTriggerId = 0
  local Trigger = defineQueryRelation("Trigger") {
    [case(1, NonNil, Nil)] = function(self, name)
      nextTriggerId = nextTriggerId + 1
      return {{name, nextTriggerId}}
    end,
    [case(2, NonNil, NonNil)] = function(self, name, id)
      return {{name, id}}
    end,
    default = Relation.empty
  }
  planner:addRelations({
    Trigger,
    createRelation("Interact"),
    createRelation("Minion")
  })

  for name,trigger in pairs(triggers) do
    trigger.statemodifiers = trigger.statemodifiers or {}
    planner:addRelations({createRelation(name.."Limiter")})
    table.insert(trigger.preconditions, {"!Trigger", {name}, "id"})
    table.insert(trigger.preconditions, {"!"..name.."Limiter"})
    table.insert(trigger.postconditions, {"Trigger", {name}, "id"})
    table.insert(trigger.statemodifiers, {name.."Limiter"})
  end
  planner:addOperators(triggers)

  for name,reaction in pairs(reactions) do
    for _,script in pairs(reaction.scripts or {}) do
      require(script)
    end
    table.insert(reaction.preconditions, {"Trigger", "triggerType", "id"})
    table.insert(reaction.postconditions, {"!Trigger", "triggerType", "id"})
  end
  planner:addOperators(reactions)
end

-- adds boss abilities to the planner
function addPlannerBossAbilities(planner, bossAbilities)
  local operators = {}
  for _,ability in pairs(bossAbilities) do
    operators[ability.name] = {
      chance = ability.chance,
      preconditions = ability.preconditions,
      postconditions = ability.postconditions,
      statemodifiers = ability.statemodifiers,
      objectives = ability.objectives
    }
  end
  planner:addOperators(operators)
end

-- helper for immediately generating a plan
function generatePlan(planner, initialState, goalState, globalState)
  local co = coroutine.create(function ()
    return planner:generatePlan(initialState, goalState, globalState)
  end)
  local status, result, state
  while coroutine.status(co) ~= "dead" do
    status, result, state = coroutine.resume(co)
    if not status then
      error(result)
      result = nil
    end
  end
  return result, state
end

-- returns a list of object interact reactions
function placeDungeonParts(plan, dungeonParts, spaceConfig)
  local interactive = {}
  for _,op in pairs(plan) do
    if dungeonParts[op.name] then
      for _,piece in pairs(dungeonParts[op.name].pieces or {}) do
        local position = vec2.add(spaceConfig.origin, vec2.mul(vec2.add(piece.offset, {0, 1}), spaceConfig.size))
        sb.logInfo("Placing dungeon piece %s at %s", piece.name, position)
        world.placeDungeon(piece.name, position)
      end

      for _,object in pairs(dungeonParts[op.name].objects or {}) do
        local position = vec2.add(spaceConfig.origin, vec2.mul(object.space, spaceConfig.size))
        position = vec2.add(position, object.offset)
        local uniqueId = sb.makeUuid()
        local placed = world.placeObject(object.name, position, 1, {
            managerUid = entity.uniqueId(),
            uniqueId = uniqueId
          })
        if placed then
          if util.find(op.preconditions, function(term) return term[1] == "Interact" end) then
            table.insert(interactive, uniqueId)
          end
        else
          sb.logInfo("Failed to place object %s at position %s", object, position)
        end
      end
    end
  end
  return interactive
end

function reactionHooks(reactionConfigs, plan)
  local hooks = {}
  for _,op in pairs(plan) do
    local reaction = reactionConfigs[op.name]
    if reaction then
      local triggerId = util.find(op.preconditions, function(term) return term[1] == "Trigger" end)[3]
      hooks[triggerId] = function(triggerPosition)
        _ENV[reaction.callback](op, plan, triggerPosition)
      end
    end
  end
  return hooks
end

function vulnerabilityType(state)
  local vulnTerm = util.find(state, function(term) return term[1] == "Vulnerability" end)
  return vulnTerm and vulnTerm[2]
end

function bossParametersFromPlan(bossAbilities, plan, state, spaceConfig)
  self.rand = self.rand or sb.makeRandomSource(storage.seed)
  local bossParameters = {}
  local behaviorConfig = {
    actions = {}
  }

  local vulnerability = vulnerabilityType(state)
  if vulnerability == "PiercingVulnerability" then
    construct(bossParameters, "statusSettings", "stats", "protection")
    construct(bossParameters, "statusSettings", "stats", "maxHealth")
    bossParameters.statusSettings.stats.protection.baseValue = 100.0
    bossParameters.statusSettings.stats.maxHealth.baseValue = 750.0
    bossParameters.shielded = true
    table.insert(behaviorConfig.actions, {
      name = "guardian-damagestun",
      parameters = {}
    })
  elseif vulnerability == "DamageVulnerability" then
    construct(bossParameters, "statusSettings", "stats", "protection")
    construct(bossParameters, "statusSettings", "stats", "maxHealth")
    if self.rand:randf() < 0.5 then
      bossParameters.statusSettings.stats.protection.baseValue = 90.0
      bossParameters.statusSettings.stats.maxHealth.baseValue = 900.0
    else
      bossParameters.statusSettings.stats.maxHealth.baseValue = 9000.0
    end
  end

  local sequenceActions = {}
  for _,op in pairs(plan) do
    local ability = copy(bossAbilities[op.name])
    if ability then
      if ability.behaviorHandler then
        ability = _ENV[ability.behaviorHandler](ability, op, plan, state, spaceConfig)
      end
      for _,action in pairs(ability.sequenceActions) do
        table.insert(sequenceActions, action)
      end
    end
  end
  -- skills that expose vulnerabilities are added to the plan first
  -- but should be performed last
  if vulnerability then
    table.insert(sequenceActions, sequenceActions[1])
    table.remove(sequenceActions, 1)
  end

  if #sequenceActions > 0 then
    local phaseSequence = {
      name = "guardian-phasesequence",
      parameters = {
        actions = {}
      }
    }

    local lastPhaseHealth = 1.1
    -- last two skills go in first phase
    if #sequenceActions > 2 then
      table.insert(phaseSequence.parameters.actions, {
          name = "attacksequence",
          parameters = {
            maxHealth = lastPhaseHealth,
            actions = util.takeEnd(sequenceActions, 2)
          }
        })
      lastPhaseHealth = 0.75
    end

    -- last four skills go in second phase
    if #sequenceActions > 4 then
      table.insert(phaseSequence.parameters.actions, 1, {
          name = "attacksequence",
          parameters = {
            maxHealth = lastPhaseHealth,
            actions = util.takeEnd(sequenceActions, 4)
          }
        })
      lastPhaseHealth = 0.5
    end

    table.insert(phaseSequence.parameters.actions, 1, {
        name = "attacksequence",
        parameters = {
          maxHealth = lastPhaseHealth,
          actions = sequenceActions
        }
      })

    table.insert(behaviorConfig.actions, phaseSequence)
  end

  bossParameters.selectedParts = {}
  if util.find(state, function(term) return term[1] == "!WeaponEquipped" end) then
    bossParameters.selectedParts.lefthand = "empty"
  else
    bossParameters.selectedParts.lefthand = util.randomFromList(config.getParameter("weaponHands"))
  end

  bossParameters.behaviorConfig = behaviorConfig
  bossParameters.musicStagehands = config.getParameter("musicStagehands")
  return bossParameters
end

function spawnBoss(bossParameters, bossUid, seed)
  bossParameters.shortdescription = root.generateName("/monsters/boss/guardianboss/bossnamegen.config:names", seed)
  bossParameters.managerUid = entity.uniqueId()
  bossParameters.level = 7
  bossParameters.uniqueId = bossUid
  bossParameters.seed = seed
  bossParameters.persistent = true
  return world.spawnMonster(string.format("%sguardianboss", storage.elementalType), entity.position(), bossParameters)
end
