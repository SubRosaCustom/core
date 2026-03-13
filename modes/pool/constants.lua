local plugin = ...

local constants = {}

constants.defaultConfig = {
	aimLeftScancode = 80, -- Left Arrow
	aimRightScancode = 79, -- Right Arrow
	powerUpScancode = 82, -- Up Arrow
	powerDownScancode = 81, -- Down Arrow
	shootScancode = 44, -- Space
	rerackScancode = 21, -- R
	joinScancode = 13, -- J
	leaveScancode = 15, -- L
	readyScancode = 40, -- Enter
	moveCueLeftScancode = 4, -- A
	moveCueRightScancode = 7, -- D
	moveCueUpScancode = 26, -- W
	moveCueDownScancode = 22, -- S
	overlayX = 150,
	overlayY = 10,
	textScale = 16.0,
}

constants.TABLE_POS = Vector(1610, 24.71, 1192)
constants.TABLE_ROT = orientations.n
constants.BALL_HEIGHT = 1.2

constants.TABLE_MIN_X = -1.36
constants.TABLE_MAX_X = 3.66
constants.TABLE_MIN_Z = -1.48
constants.TABLE_MAX_Z = 1.48
constants.TABLE_CENTER_X = (constants.TABLE_MIN_X + constants.TABLE_MAX_X) * 0.5
constants.HEAD_STRING_X = 2.10
constants.CUE_START_X = 2.51
constants.CUE_START_Z = 0.0

constants.BALL_RADIUS = 0.10
constants.BALL_DIAMETER = constants.BALL_RADIUS * 2.0
constants.POCKET_RADIUS = 0.24

constants.TABLE_FRICTION = 0.985
constants.RAIL_BOUNCE = 0.96
constants.COLLISION_DAMPING = 0.995
constants.STOP_EPSILON = 0.0005

constants.AIM_STEP = 0.03
constants.POWER_STEP = 0.04
constants.MIN_SHOT_POWER = 0.20
constants.MAX_SHOT_POWER = 1.00
constants.SHOT_POWER_SCALE = 0.08
constants.CUE_MOVE_STEP = 0.035

constants.BINDS = {
	aimLeft = "pool_aim_left",
	aimRight = "pool_aim_right",
	powerUp = "pool_power_up",
	powerDown = "pool_power_down",
	shoot = "pool_shoot",
	rerack = "pool_rerack",
	join = "pool_join",
	leave = "pool_leave",
	ready = "pool_ready",
	moveCueLeft = "pool_move_cue_left",
	moveCueRight = "pool_move_cue_right",
	moveCueUp = "pool_move_cue_up",
	moveCueDown = "pool_move_cue_down",
}

constants.EVENTS = {
	requestState = "srcc.pool.request_state",
	command = "srcc.pool.command",
	state = "srcc.pool.state",
	notice = "srcc.pool.notice",
}

constants.RESUBSCRIBE_TICKS = 180
constants.STATE_TIMEOUT_TICKS = 360

constants.modelNames = { "table", "cue", "cueball" }
for i = 1, 15 do
	table.insert(constants.modelNames, "ball" .. i)
end

constants.rackOffsets = {}
do
	local rackApexX = 1.15
	local rackSpacingX = 0.18
	local rackSpacingZ = 0.2
	local rackIndex = 1

	for row = 0, 4 do
		for col = 0, row do
			constants.rackOffsets[rackIndex] = {
				x = rackApexX + (row * rackSpacingX),
				z = (col - (row * 0.5)) * rackSpacingZ,
			}
			rackIndex = rackIndex + 1
		end
	end
end

constants.pocketCenters = {
	{ x = constants.TABLE_MIN_X, z = constants.TABLE_MIN_Z },
	{ x = constants.TABLE_MIN_X, z = constants.TABLE_MAX_Z },
	{ x = constants.TABLE_MAX_X, z = constants.TABLE_MIN_Z },
	{ x = constants.TABLE_MAX_X, z = constants.TABLE_MAX_Z },
	{ x = constants.TABLE_CENTER_X, z = constants.TABLE_MIN_Z },
	{ x = constants.TABLE_CENTER_X, z = constants.TABLE_MAX_Z },
}

function constants.wrapAngle(angle)
	local twoPi = math.pi * 2
	while angle > math.pi do
		angle = angle - twoPi
	end
	while angle < -math.pi do
		angle = angle + twoPi
	end
	return angle
end

function constants.formatGroup(group)
	if group == "solids" then
		return "Solids"
	end
	if group == "stripes" then
		return "Stripes"
	end
	return "-"
end

function constants.localToWorld(x, z)
	return constants.TABLE_POS + (Vector(x, constants.BALL_HEIGHT, z) * constants.TABLE_ROT)
end

return constants
