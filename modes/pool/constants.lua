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
	readyScancode = 19, -- P
	moveCueLeftScancode = 4, -- A
	moveCueRightScancode = 7, -- D
	moveCueUpScancode = 26, -- W
	moveCueDownScancode = 22, -- S
	cameraModeScancode = 5, -- B
	hudModeScancode = 17, -- N
	textScale = 16.0,
}

constants.SCREEN_WIDTH = 1024
constants.SCREEN_HEIGHT = 576
constants.HUD_MARGIN = 18
constants.HUD_RIGHT_WIDTH = 314
constants.HUD_TOP_HEIGHT = 86
constants.HUD_BOTTOM_HEIGHT = 88
constants.HUD_CARD_RADIUS = 0

constants.TABLE_POS = Vector(1610, 23.91, 1192)
constants.TABLE_ROT = orientations.n
constants.BALL_HEIGHT = 1.2
constants.CAMERA_FOV = 0.82
constants.SPECTATOR_CAMERA_POS_LOCAL = Vector(-0.85, 3.1, 0.0)
constants.SPECTATOR_CAMERA_TARGET_LOCAL = Vector(1.45, 1.05, 0.0)
constants.SEAT_CAMERA_POS_LOCAL = {
	[1] = Vector(-0.35, 2.45, -1.45),
	[2] = Vector(-0.35, 2.45, 1.45),
}
constants.SEAT_CAMERA_TARGET_LOCAL = {
	[1] = Vector(1.55, 1.10, -0.08),
	[2] = Vector(1.55, 1.10, 0.08),
}
constants.CAMERA_MODE_ORDER = {
	"follow",
}
constants.CAMERA_MODE_LABELS = {
	follow = "Camera: Follow",
}
constants.HUD_MODE_ORDER = {
	"full",
	"compact",
	"hidden",
}
constants.HUD_MODE_LABELS = {
	full = "HUD: Full",
	compact = "HUD: Compact",
	hidden = "HUD: Hidden",
}

constants.TABLE_MIN_X = -2.76
constants.TABLE_MAX_X = 2.26
constants.TABLE_MIN_Z = -1.48
constants.TABLE_MAX_Z = 1.48
constants.TABLE_CENTER_X = (constants.TABLE_MIN_X + constants.TABLE_MAX_X) * 0.5
constants.HEAD_STRING_X = -1.20
constants.CUE_START_X = -1.55
constants.CUE_START_Z = 0.0

constants.BALL_RADIUS = 0.10
constants.BALL_DIAMETER = constants.BALL_RADIUS * 2.0
constants.POCKET_SPHERE_RADIUS = 0.29
constants.POCKET_CENTER_DEPTH = 0.14
constants.DEBUG_LINE_HEIGHT = 1.65
constants.DEBUG_ZONE_HEIGHT = 1.56
constants.DEBUG_ZONE_THICKNESS = 0.06
constants.DEBUG_PREDICTION_STEPS = 8
constants.BALL_PLACE_ANIM_TICKS = 10
constants.BALL_PLACE_HEIGHT = 0.42
constants.BALL_SINK_ANIM_TICKS = 12
constants.BALL_SINK_DEPTH = 0.54
constants.PHYSICS_SUBSTEPS = 3

constants.TABLE_FRICTION = 0.992
constants.RAIL_BOUNCE = 0.96
constants.COLLISION_DAMPING = 0.995
constants.STOP_EPSILON = 0.0005

constants.AIM_STEP = 0.03
constants.POWER_STEP = 0.04
constants.MIN_SHOT_POWER = 0.20
constants.MAX_SHOT_POWER = 1.00
constants.SHOT_POWER_SCALE = 0.16
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
	cameraMode = "pool_camera_mode",
	hudMode = "pool_hud_mode",
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
	local rackApexX = -0.25
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

do
	local cornerOffset = constants.BALL_RADIUS
	local sideOffset = constants.BALL_RADIUS
	local pocketY = constants.BALL_HEIGHT - constants.POCKET_CENTER_DEPTH
	constants.pocketCenters = {
		{ x = constants.TABLE_MIN_X - cornerOffset, y = pocketY, z = constants.TABLE_MIN_Z - cornerOffset },
		{ x = constants.TABLE_MIN_X - cornerOffset, y = pocketY, z = constants.TABLE_MAX_Z + cornerOffset },
		{ x = constants.TABLE_MAX_X + cornerOffset, y = pocketY, z = constants.TABLE_MIN_Z - cornerOffset },
		{ x = constants.TABLE_MAX_X + cornerOffset, y = pocketY, z = constants.TABLE_MAX_Z + cornerOffset },
		{ x = constants.TABLE_CENTER_X, y = pocketY, z = constants.TABLE_MIN_Z - sideOffset },
		{ x = constants.TABLE_CENTER_X, y = pocketY, z = constants.TABLE_MAX_Z + sideOffset },
	}
end

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

function constants.localToWorld(x, z, y)
	return constants.TABLE_POS + (Vector(x, y or constants.BALL_HEIGHT, z) * constants.TABLE_ROT)
end

function constants.tableCameraPosition(seat)
	local localPos = constants.SEAT_CAMERA_POS_LOCAL[seat] or constants.SPECTATOR_CAMERA_POS_LOCAL
	return constants.TABLE_POS + (localPos * constants.TABLE_ROT)
end

function constants.tableCameraTarget(seat)
	local localTarget = constants.SEAT_CAMERA_TARGET_LOCAL[seat] or constants.SPECTATOR_CAMERA_TARGET_LOCAL
	return constants.TABLE_POS + (localTarget * constants.TABLE_ROT)
end

function constants.nextMode(order, current)
	local count = #order
	if count == 0 then
		return current
	end

	for i = 1, count do
		if order[i] == current then
			return order[(i % count) + 1]
		end
	end

	return order[1]
end

local function applyNumberField(data, key, current)
	local value = data[key]
	local parsed = tonumber(value)
	if parsed == nil then
		return current
	end
	return parsed
end

function constants.applyServerConstants(data)
	if type(data) ~= "table" then
		return false
	end

	constants.TABLE_MIN_X = applyNumberField(data, "tableMinX", constants.TABLE_MIN_X)
	constants.TABLE_MAX_X = applyNumberField(data, "tableMaxX", constants.TABLE_MAX_X)
	constants.TABLE_MIN_Z = applyNumberField(data, "tableMinZ", constants.TABLE_MIN_Z)
	constants.TABLE_MAX_Z = applyNumberField(data, "tableMaxZ", constants.TABLE_MAX_Z)
	constants.TABLE_CENTER_X = (constants.TABLE_MIN_X + constants.TABLE_MAX_X) * 0.5
	constants.HEAD_STRING_X = applyNumberField(data, "headStringX", constants.HEAD_STRING_X)
	constants.CUE_START_X = applyNumberField(data, "cueStartX", constants.CUE_START_X)
	constants.CUE_START_Z = applyNumberField(data, "cueStartZ", constants.CUE_START_Z)
	constants.BALL_RADIUS = applyNumberField(data, "ballRadius", constants.BALL_RADIUS)
	constants.BALL_DIAMETER = constants.BALL_RADIUS * 2.0
	constants.POCKET_SPHERE_RADIUS = applyNumberField(data, "pocketRadius", constants.POCKET_SPHERE_RADIUS)
	constants.TABLE_FRICTION = applyNumberField(data, "tableFriction", constants.TABLE_FRICTION)
	constants.RAIL_BOUNCE = applyNumberField(data, "railBounce", constants.RAIL_BOUNCE)
	constants.COLLISION_DAMPING = applyNumberField(data, "collisionDamping", constants.COLLISION_DAMPING)
	constants.STOP_EPSILON = applyNumberField(data, "stopEpsilon", constants.STOP_EPSILON)
	constants.PHYSICS_SUBSTEPS = applyNumberField(data, "physicsSubsteps", constants.PHYSICS_SUBSTEPS)
	constants.AIM_STEP = applyNumberField(data, "aimStep", constants.AIM_STEP)
	constants.POWER_STEP = applyNumberField(data, "powerStep", constants.POWER_STEP)
	constants.MIN_SHOT_POWER = applyNumberField(data, "minShotPower", constants.MIN_SHOT_POWER)
	constants.MAX_SHOT_POWER = applyNumberField(data, "maxShotPower", constants.MAX_SHOT_POWER)
	constants.SHOT_POWER_SCALE = applyNumberField(data, "shotPowerScale", constants.SHOT_POWER_SCALE)
	constants.CUE_MOVE_STEP = applyNumberField(data, "cueMoveStep", constants.CUE_MOVE_STEP)

	local incomingPockets = data.pocketCenters
	if type(incomingPockets) == "table" then
		local pocketY = constants.BALL_HEIGHT - constants.POCKET_CENTER_DEPTH
		local mapped = {}
		for i = 1, #incomingPockets do
			local pocket = incomingPockets[i]
			if type(pocket) == "table" then
				local x = tonumber(pocket.x)
				local z = tonumber(pocket.z)
				if x ~= nil and z ~= nil then
					mapped[#mapped + 1] = {
						x = x,
						y = pocketY,
						z = z,
					}
				end
			end
		end

		if #mapped > 0 then
			constants.pocketCenters = mapped
		end
	end

	return true
end

return constants
