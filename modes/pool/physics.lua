local plugin = ...
local constants = plugin:require("constants")

local physics = {}

function physics.runPhysicsTick(context, state)
	local stopEpsilonSq = constants.STOP_EPSILON * constants.STOP_EPSILON

	for _, ball in ipairs(context.balls) do
		if ball.active then
			ball.x = ball.x + ball.vx
			ball.z = ball.z + ball.vz

			ball.vx = ball.vx * constants.TABLE_FRICTION
			ball.vz = ball.vz * constants.TABLE_FRICTION

			local speedSq = (ball.vx * ball.vx) + (ball.vz * ball.vz)
			if speedSq <= stopEpsilonSq then
				ball.vx = 0
				ball.vz = 0
			end
		end
	end

	local pocketRadiusSq = constants.POCKET_RADIUS * constants.POCKET_RADIUS
	for _, ball in ipairs(context.balls) do
		if ball.active then
			for i = 1, #constants.pocketCenters do
				local pocket = constants.pocketCenters[i]
				local dx = ball.x - pocket.x
				local dz = ball.z - pocket.z
				if (dx * dx) + (dz * dz) <= pocketRadiusSq then
					state.pocketBall(context, ball)
					break
				end
			end
		end
	end

	local minX = constants.TABLE_MIN_X + constants.BALL_RADIUS
	local maxX = constants.TABLE_MAX_X - constants.BALL_RADIUS
	local minZ = constants.TABLE_MIN_Z + constants.BALL_RADIUS
	local maxZ = constants.TABLE_MAX_Z - constants.BALL_RADIUS

	for _, ball in ipairs(context.balls) do
		if ball.active then
			if ball.x < minX then
				ball.x = minX
				ball.vx = math.abs(ball.vx) * constants.RAIL_BOUNCE
			elseif ball.x > maxX then
				ball.x = maxX
				ball.vx = -math.abs(ball.vx) * constants.RAIL_BOUNCE
			end

			if ball.z < minZ then
				ball.z = minZ
				ball.vz = math.abs(ball.vz) * constants.RAIL_BOUNCE
			elseif ball.z > maxZ then
				ball.z = maxZ
				ball.vz = -math.abs(ball.vz) * constants.RAIL_BOUNCE
			end
		end
	end

	local diameterSq = constants.BALL_DIAMETER * constants.BALL_DIAMETER
	for i = 1, (#context.balls - 1) do
		local a = context.balls[i]
		if a.active then
			for j = i + 1, #context.balls do
				local b = context.balls[j]
				if b.active then
					local dx = b.x - a.x
					local dz = b.z - a.z
					local distSq = (dx * dx) + (dz * dz)

					if distSq > 0 and distSq < diameterSq then
						local dist = math.sqrt(distSq)
						local nx = dx / dist
						local nz = dz / dist

						local overlap = constants.BALL_DIAMETER - dist
						local push = (overlap * 0.5) + 0.0001
						a.x = a.x - (nx * push)
						a.z = a.z - (nz * push)
						b.x = b.x + (nx * push)
						b.z = b.z + (nz * push)

						local rvx = b.vx - a.vx
						local rvz = b.vz - a.vz
						local relSpeed = (rvx * nx) + (rvz * nz)
						if relSpeed < 0 then
							local impulse = -relSpeed
							a.vx = a.vx - (nx * impulse)
							a.vz = a.vz - (nz * impulse)
							b.vx = b.vx + (nx * impulse)
							b.vz = b.vz + (nz * impulse)

							a.vx = a.vx * constants.COLLISION_DAMPING
							a.vz = a.vz * constants.COLLISION_DAMPING
							b.vx = b.vx * constants.COLLISION_DAMPING
							b.vz = b.vz * constants.COLLISION_DAMPING
						end

						if context.shotInProgress and context.firstHitGroup == nil then
							if a.group == "cue" and b.group ~= "cue" then
								context.firstHitGroup = b.group
							elseif b.group == "cue" and a.group ~= "cue" then
								context.firstHitGroup = a.group
							end
						end
					end
				end
			end
		end
	end
end

function physics.resolveShot(context, state)
	local shooter = context.turnPlayer
	local opponent = (shooter == 1) and 2 or 1
	local shooterGroup = context.assignments[shooter]

	local legalTarget = "open"
	if shooterGroup then
		if state.countActiveGroup(context, shooterGroup) > 0 then
			legalTarget = shooterGroup
		else
			legalTarget = "eight"
		end
	end

	local pocketedSolids = 0
	local pocketedStripes = 0
	local pocketedEight = false
	for _, ball in ipairs(context.pocketedThisShot) do
		if ball.group == "solids" then
			pocketedSolids = pocketedSolids + 1
		elseif ball.group == "stripes" then
			pocketedStripes = pocketedStripes + 1
		elseif ball.group == "eight" then
			pocketedEight = true
		end
	end

	local foul = false
	local foulReason = nil

	if context.cueBallPocketedThisShot then
		foul = true
		foulReason = "scratch"
	elseif context.firstHitGroup == nil then
		foul = true
		foulReason = "no first contact"
	elseif legalTarget == "open" then
		if context.firstHitGroup == "eight" then
			foul = true
			foulReason = "8-ball first on open table"
		end
	elseif legalTarget == "eight" then
		if context.firstHitGroup ~= "eight" then
			foul = true
			foulReason = "must hit 8-ball first"
		end
	elseif context.firstHitGroup ~= legalTarget then
		foul = true
		foulReason = "wrong first ball"
	end

	if pocketedEight then
		if legalTarget == "eight" and not foul then
			context.winner = shooter
			context.statusLine = "Player " .. shooter .. " wins by pocketing the 8-ball."
		else
			context.winner = opponent
			context.statusLine = "Player " .. shooter .. " fouled the 8-ball. Player " .. opponent .. " wins."
		end
		context.ballInHand = false
		state.resetRoundState(context)
		return
	end

	if context.assignments[shooter] == nil and not foul then
		if pocketedSolids > 0 and pocketedStripes == 0 then
			context.assignments[shooter] = "solids"
			context.assignments[opponent] = "stripes"
		elseif pocketedStripes > 0 and pocketedSolids == 0 then
			context.assignments[shooter] = "stripes"
			context.assignments[opponent] = "solids"
		end
	end

	shooterGroup = context.assignments[shooter]
	local pocketedOwn = false
	if shooterGroup == "solids" then
		pocketedOwn = pocketedSolids > 0
	elseif shooterGroup == "stripes" then
		pocketedOwn = pocketedStripes > 0
	else
		pocketedOwn = (pocketedSolids + pocketedStripes) > 0
	end

	if foul then
		context.turnPlayer = opponent
		context.ballInHand = true
		state.placeCueBallForHand(context)
		context.statusLine = "Foul (" .. tostring(foulReason) .. "). Player " .. context.turnPlayer .. " has ball in hand."
	else
		context.ballInHand = false
		if pocketedOwn then
			context.statusLine = "Player " .. shooter .. " continues."
		else
			context.turnPlayer = opponent
			context.statusLine = "Turn passes to Player " .. context.turnPlayer .. "."
		end
	end

	state.resetRoundState(context)
end

function physics.logicTick(context, state)
	if state.ballsAreMoving(context) then
		physics.runPhysicsTick(context, state)
	end

	if context.shotInProgress and not state.ballsAreMoving(context) then
		physics.resolveShot(context, state)
	end
end

return physics
