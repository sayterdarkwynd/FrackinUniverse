function setTimeToLive(args, board)
  if args.timeToLive == 0 or args.timeToLive == nil then
    return false
  end
  local params = args.config
  params.timeToLive = args.timeToLive
  return true, {params=params}
end
