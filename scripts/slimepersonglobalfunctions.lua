-- Usage: hex2rgb("#a85636") result:
function hex2rgb(hex)
    hex = hex:gsub("#","")
	local rgbValue = tonumber("0x"..hex:sub(1,2)) .. "," .. tonumber("0x"..hex:sub(3,4)) .. "," .. tonumber("0x"..hex:sub(5,6))
    return rgbValue
end

-- local myString = "100, 200, 300, 400"
-- local splited = myString:split(",") it can be any delimiter
-- Result: Splited = {100, 200, 300, 400}
function string:split( inSplitPattern, outResults ) -- luacheck: ignore 142
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function damaged()
  if self.active then
    self.damageDisableTimer = self.damageDisableTime
  end
end
