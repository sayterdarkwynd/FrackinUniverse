---------------------------------------------------------------
-- ROUNDING
---------------------------------------------------------------
-- param number
-- output result
function floor(args, board)
  local result = math.floor(args.number)
  return true, {result = result}
end
