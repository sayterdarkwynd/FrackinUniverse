function FRHelper:call(args)
  if status.isResource("food") then
    local foodPrice = args.food or -0.02    -- default value (2% reduction)
    status.modifyResource("food", status.resource("food") * foodPrice )
  end
end
