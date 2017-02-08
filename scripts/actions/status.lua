-- param resource
-- param percentage
function resourcePercentage(args, output)
  args = parseArgs(args, {
    resource = "health",
    percentage = 1
  })

  return status.resourcePercentage(args.resource) > args.percentage
end

-- param statName
-- output value
function stat(args, output)
  args = parseArgs(args, {
    statName = nil
  })

  BData:setNumber(output.value, status.stat(args.statName))
  return true
end

-- param resource
-- param amount
function setResource(args, output)
  args = parseArgs(args, {
    resource = "health",
    amount = 100
  })

  status.setResource(args.resource, args.amount)
  return true
end

-- param resource
-- param percentage
function setResourcePercentage(args, output)
  args = parseArgs(args, {
    resource = "health",
    percentage = 1
  })

  local percentage = BData:getNumber(args.percentage)
  status.setResourcePercentage(args.resource, percentage)
  return true
end

-- param name
-- param duration
function addEphemeralEffect(args, output)
  args = parseArgs(args, {
  })
  if args.name == nil or args.name == "" then return false end

  local duration = BData:getNumber(args.duration)
  status.addEphemeralEffect(args.name, duration)
  return true
end

-- param name
function removeEphemeralEffect(args, output)
  args = parseArgs(args, {
  })
  if args.name == nil then return false end

  status.removeEphemeralEffect(args.name)
  return true
end

-- param category
-- param stat
-- param amount
function addStatModifier(args, output)
  args = parseArgs(args, {
    category = "default",
    stat = nil,
    amount = nil
  })

  local amount = BData:getNumber(args.amount)
  if args.stat == nil or amount == nil then return false end

  status.addPersistentEffect(args.category, {stat = args.stat, amount = amount})
  return true
end

-- param category
function clearPersistentEffects(args, output)
  args = parseArgs(args, {
    category = "default"
  })

  status.setPersistentEffects(args.category, {})
  return true
end

function suicide(args, output)
  status.setResource("health", 0)
  return true
end
