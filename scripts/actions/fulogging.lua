function logValue(args, board)
  local value
  if args.entity ~= nil then value = args.entity
  elseif args.bool ~= nil then value = args.bool
  elseif args.number ~= nil then value = args.number
  elseif args.position ~= nil then value = args.position
  elseif args.vector ~= nil then value = args.vector
  elseif args.list ~= nil then value = args.list
  elseif args.table ~= nil then value = args.table
  elseif args.string ~= nil then value = args.string
  else return false end
  sb.logInfo(args.text, value)
  return true
end
