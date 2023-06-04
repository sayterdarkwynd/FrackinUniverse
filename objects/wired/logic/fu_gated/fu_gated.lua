-- this object is intended as a protected dungeon object
-- parameters:
--   inputValue: number representing which inputs are required to be on, or unset (defaults to random from connected inputs)
--   inputBits: number of inputs which are required to be on, or unset (defaults to half of connected inputs, rounded up)
-- only one should be specified

function init()

	storage.input = config.getParameter('inputValue') -- default: random
	storage.bits = {0, 1, 2, 3, 4, 5, 6, 7} -- assume all connected

	if storage.input == nil then
		local inputBits = config.getParameter('inputBits') -- default: half of those connected, rounded up
		-- see which nodes are connected
		local numConnected = 0
		storage.bits = {}
		local nodes = object.inputNodeCount()
		for i = 0, nodes - 1 do
			if object.isInputNodeConnected(i) then
				table.insert(storage.bits, i)
				numConnected = numConnected + 1
			end
		end
		-- pick some of them at random
		local rnd = sb.makeRandomSource()
		local selected = {}
		storage.input = 0
		inputBits = inputBits or math.ceil (numConnected / 2)
		for _ = 1, math.min(numConnected, inputBits) do
			local bit
			while true do
				bit = rnd:randInt(1, numConnected)
				if not bit or not selected[bit] then break end
			end
			selected[bit] = true
			storage.input = storage.input + (2 ^ storage.bits[bit])
		end
	end

	onInputNodeChange()
end

function onNodeConnectionChange()
	init()
end

function onInputNodeChange(node, level)
	-- ignoring parameters
	local input = 0
	for _, bit in ipairs(storage.bits) do
		if object.getInputNodeLevel(bit) then input = input + (2 ^ bit) end
	end
	object.setOutputNodeLevel(0, input == storage.input)
end
