
--		Functions:
--	# marks optional parameters

--	DeepPrintTable(table) : Prints the given table to the log
--		table	- The table you want to print (Can shove any other value, but it ill just print it as it is)

--	FadeHex(string, string, integer, string) : Returns a modified two-digit hex faded in the requested direction of the recieved two-digit hex
--		string	- Two-digit hex string, such as "FF" or "13" or "E4"
--		string	- "out" or "in", depending on the direction you want it to fade to. "out" strive to "00", and "in" strives to "FF"
--		integer	- By how much you want to modify the hex value
--	#	string	- Target hex value the modification should not exceed. If fading in, and increasing "10" hex by 5, but target is "13", it will go up to "13" instead of to "15"

-- RollDice(integer, integer, integer) : Returns a value of a simulated dice roll. (Ever wanted to use a simple 2d4 somewhere before?)
--		integer	- Amount of rolled dice
--		integer	- Dice sides
--	#	integer - Static modifier that is added to the final value


function DeepPrintTable(tbl)
	sb.logInfo("%s", _DeepPrintTableHelper(tbl, 0))
end

function _DeepPrintTableHelper(toPrint, level)
	level = level or 0
	local str = ""
	
	if type(toPrint) == "table" then
		for k, v in pairs(toPrint) do
			for i = 0, level do
				str = str.."	"
			end
			
			local lenFix = ""
			for i = 1, 30 - string.len(tostring(k)) do 
				lenFix = lenFix.." "
			end
			
			str = str..tostring(k)..lenFix.."=          "..tostring(v)
			
			if type(v) == "table" then
				str = str.._DeepPrintTableHelper(v, level +1).."\n"
			else
				str = str.."\n"
			end
		end
	
	else
		str = tostring(toPrint)
	end
	
	return "\n"..str
end

-- Hex code char-number values 
cb = {}
cb[70] = 15	-- F
cb[69] = 14	-- E
cb[68] = 13	-- D
cb[67] = 12	-- C
cb[66] = 11	-- B
cb[65] = 10	-- A
cb[57] = 9	-- 9
cb[56] = 8	-- 8
cb[55] = 7	-- 7
cb[54] = 6	-- 6
cb[53] = 5	-- 5
cb[52] = 4	-- 4
cb[51] = 3	-- 3
cb[50] = 2	-- 2
cb[49] = 1	-- 1
cb[48] = 0	-- 0

function FadeHex(hex, fade, amount, target)
	hex = string.upper(hex)
	amount = math.ceil(amount)
	fade = string.lower(fade)
	
	if target then target = string.upper(target) end
	if hex == target then return hex end
	
	if fade == "out" then
		local tens = cb[string.byte(string.sub(hex, 1, 1))]
		local units = cb[string.byte(string.sub(hex, 2, 2))]
		units = units - amount
		
		while units < 0 do
			units = units + 15
			tens = tens - 1
			
			if target then
				local tTens = cb[string.byte(string.sub(target, 1, 1))]
				local tUnits = cb[string.byte(string.sub(target, 2, 2))]
				
				if tens <= tTens then
					return target
				end
			elseif tens < 0 then
				tens = 0
				units = 0
				break
			end
		end
		
		for i, j in pairs(cb) do
			if units == j then
				units = i
			end
			
			if tens == j then
				tens = i
			end
		end
		
		return string.char(tens)..string.char(units)
		
	elseif fade == "in" then
		local tens = cb[string.byte(string.sub(hex, 1, 1))]
		local units = cb[string.byte(string.sub(hex, 2, 2))]
		units = units + amount
		
		while units > 15 do
			units = units - 15
			tens = tens + 1
			
			if target then
				local tTens = cb[string.byte(string.sub(target, 1, 1))]
				local tUnits = cb[string.byte(string.sub(target, 2, 2))]
				
				if tens >= tTens then
					return target
				end
			elseif tens > 15 then
				tens = 15
				units = 15
				break
			end
		end
		
		for i, j in pairs(cb) do
			if units == j then
				units = i
			end
			
			if tens == j then
				tens = i
			end
		end
		
		return string.char(tens)..string.char(units)
	end
end

function RollDice(dice, sides, mod)
	local sum = mod or 0
	
	for i = 1, dice do
		sum = sum + math.random(1, sides)
	end
	
	return sum
end
