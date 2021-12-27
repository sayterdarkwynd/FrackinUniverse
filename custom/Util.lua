function lerp(_value, _to, _smoothness)
	return _value + ((_to - _value) / _smoothness)
end

function transform(_value, _to, _interval)
	return _value + (_to / _interval)
end

function vectorMul(vector, scalarOrVector)
	if type(scalarOrVector) == "table" then
		return {
			vector[1] * scalarOrVector[1],
			vector[2] * scalarOrVector[2]
		}
	else
		return {
			vector[1] * scalarOrVector,
			vector[2] * scalarOrVector
		}
	end
end

function vectorDiv(vector,scalar)
	return {
		vector[1] / scalar,
		vector[2] / scalar
	}
end

function vectorMag(vector)
	return math.sqrt(vector[1] * vector[1] + vector[2] * vector[2])
end

function vectorNorm(vector)
	return vectorDiv(vector, vectorMag(vector))
end

function vectorAdd(vector, scalarOrVector)
	if type(scalarOrVector) == "table" then
		return {
			vector[1] + scalarOrVector[1],
			vector[2] + scalarOrVector[2]
		}
	else
		return {
			vector[1] + scalarOrVector,
			vector[2] + scalarOrVector
		}
	end
end

function vectorSub(vector, scalarOrVector)
	if type(scalarOrVector) == "table" then
		return {
			vector[1] - scalarOrVector[1],
			vector[2] - scalarOrVector[2]
		}
	else
		return {
			vector[1] - scalarOrVector,
			vector[2] - scalarOrVector
		}
	end
end

function angleDiff(angle0, angle1)
    return ((((angle0 - angle1) % 360) + 540) % 360) - 180;
end

function aimAngle()
	return activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
end

function aimVector()
	local aimVector = vec2.rotate({1, 0}, self.aimAngle)
	aimVector[1] = aimVector[1] * self.aimDirection
	return aimVector
end

function firePosition()
	return vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("wateringcan", "waterPoint")))
end

function setTransformationGroup(_group, _rotation, _rotationPoint, _translation)
	animator.resetTransformationGroup(_group)
	animator.translateTransformationGroup(_group, _translation)
	animator.rotateTransformationGroup(_group, _rotation * math.pi / 180, vectorAdd(_rotationPoint, _translation))
end

function updateTransformationGroup(_group, _rotation, _rotationPoint, _translation)
	animator.translateTransformationGroup(_group, _translation)
	animator.rotateTransformationGroup(_group, _rotation * math.pi / 180, vectorAdd(_rotationPoint, _translation))
end

function updateAim()
	self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
	activeItem.setArmAngle(self.aimAngle)
	activeItem.setFacingDirection(self.aimDirection)
end

function updateHand(alwaysFront)
	local isFrontHand = (activeItem.hand() == "primary") == (mcontroller.facingDirection() < 0)
	--local isBackHand = (activeItem.hand() == "primary") == (mcontroller.facingDirection() > 0)
	animator.setGlobalTag("hand", isFrontHand and "front" or "back")
	if alwaysFront then
		activeItem.setOutsideOfHand(isFrontHand)
	else
		activeItem.setOutsideOfHand(false)
	end
end

function clamp(val, min, max)
	return math.max(min, math.min(val, max))
end

function updatePalette()
	animator.setGlobalTag("directives", "" .. self.elementDirectives[self.element + 1])
end

function toPx(val)
	return val / 8
end

function randomInRange(range)
	return -range + math.random() * 2 * range
end

function randomOffset(range)
	return {randomInRange(range), randomInRange(range)}
end

function drawLine(_point1, _point2, _size, _color, _layer)
	local lineDistance = world.distance(_point1, _point2)
	local lineAngle = math.atan(lineDistance[2],  lineDistance[1])
	local lineLength = world.magnitude(_point1, _point2)
	local height = math.ceil(_size) or 1
	--local light = hexToRGB(_color:sub(1, 6)) or "FFFFFF"

	world.spawnProjectile("invisibleprojectile", sb.interpolateSinEase(0.5, _point1, _point2), activeItem.ownerEntityId(), {0, 0}, true, {
		damageType = "NoDamage",
		timeToLive = 0,
		actionOnReap = {{
			action = "particle",
			specification = {
				type = "textured",
				layer = _layer,
				fullbright = true,
				collidesForeground = false,
				destructionAction = "fade",
				size = 1,
				destructionTime = 0.075,
				image = "/animations/ember3/ember3.png:2?replace;DA5302=" .. _color .. "?scalenearest=" .. math.ceil(lineLength * 8) .. ";" .. height,
				rotation = lineAngle * 180 / math.pi,
				timeToLive = 0.025,
				position = {0, 0},
				initialVelocity = {0, 0}
			}
		}}
	})
end

function drawLightning(startLine, endLine, displacement, minDisplacement, forks, forkAngleRange, width, color, layer)
	if displacement < minDisplacement then
		--local position = startLine
		drawLine(startLine, endLine, width, color, layer)
	else
		local mid = {(startLine[1] + endLine[1]) / 2, (startLine[2] + endLine[2]) / 2}
		mid = vec2.add(mid, randomOffset(displacement))
		drawLightning(startLine, mid, displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color, layer)
		drawLightning(mid, endLine, displacement / 2, minDisplacement, forks - 1, forkAngleRange, width, color, layer)

		if forks > 0 then
			local direction = vec2.sub(mid, startLine)
			local length = vec2.mag(direction) / 2
			local angle = math.atan(direction[2], direction[1]) + randomInRange(forkAngleRange)
			forkEnd = vec2.mul({math.cos(angle), math.sin(angle)}, length)
			drawLightning(mid, vec2.add(mid, forkEnd), displacement / 2, minDisplacement, forks - 1,
				forkAngleRange, math.max(width - 1, 1), color, layer)
		end
	end
end

function hexToRGB(_hex)
	if type(_hex) == "string" then
		local h = _hex
		if h:len() == 6 then
			local red = h:sub(1, 2)
			local green = h:sub(3, -3)
			local blue = h:sub(-2, -1)

			local r = rawHexToDec(red)
			local g = rawHexToDec(green)
			local b = rawHexToDec(blue)
			return {r, g, b}
		elseif h:len() == 8 then
			return {0, 0, 0}
		end
	else
		return {0, 0, 0}
	end
end

function rawHexToDec(_hex)
	if type(_hex) == "string" then
		local h = _hex:lower()
		local charray = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"}
		local total = 0
		for i = 1, h:len(), 1 do
			local c = h:sub(h:len() - i + 1, -1 * i)
			for v,x in ipairs(charray) do
				if c == x then
					total = total + ((v - 1) * 16 ^ (i - 1))
				end
			end
		end
		return total
	else
		return 0
	end
end
