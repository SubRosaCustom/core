--# selene: allow(unused_variable)
--# selene: allow(unscoped_variables)
---@meta

-- Globals exposed to synced client Lua by the SRC client runtime.
-- The runtime is sandboxed: package, io, debug, ffi and jit are removed,
-- os only provides os.clock, and loadfile/dofile/require resolve against the
-- synced script set (paths relative to scripts/, dots map to slashes).

---Key was just released this tick.
KEY_UP = 0
---Key is being held down this tick.
KEY_DOWN = 1
---Key was just pressed this tick.
KEY_PRESSED = 2

---Horizontal center alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_CENTER_X = 0x1
---Right alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_RIGHT = 0x2
---Vertical center alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_CENTER_Y = 0x4
---Bottom alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_BOTTOM = 0x8

---Named alignment flags for `renderer:drawTexture`.
---@class DrawTextureAlignGlobal
---@field CENTER_X integer
---@field RIGHT integer
---@field CENTER_Y integer
---@field BOTTOM integer
DrawTextureAlign = {}

---Anchor points for HUD widget positioning. See SrcHudWidgets.
---@class HudAnchorGlobal
---@field TOP_LEFT integer
---@field TOP_CENTER integer
---@field TOP_RIGHT integer
---@field CENTER_LEFT integer
---@field CENTER integer
---@field CENTER_RIGHT integer
---@field BOTTOM_LEFT integer
---@field BOTTOM_CENTER integer
---@field BOTTOM_RIGHT integer
HudAnchor = {}

---The local client state; only one instance in the global variable `client`.
---@type SrcLocalClient
client = nil

---Rendering API exposed by the client runtime; only one instance in the
---global variable `renderer`.
---2D drawing uses the game's virtual 1024x576 screen space.
---@type SrcRenderer
renderer = nil

---Sound API exposed by the client runtime.
---@type SrcSounds
sounds = nil

---The active configuration table loaded from the synced config.yml.
---@type table
config = {}

---Create a new Vector with 0 for every coordinate.
---@return Vector vector The created vector.
function Vector() end

---Create a new Vector with given coordinates.
---@param x number
---@param y number
---@param z number
---@return Vector vector The created vector.
function Vector(x, y, z) end

---Create an empty RotMatrix with 0 for every component.
---@return RotMatrix rotMatrix The created rotation matrix.
function RotMatrix() end

---Create a new RotMatrix.
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@return RotMatrix rotMatrix The created rotation matrix.
function RotMatrix(x1, y1, z1, x2, y2, z2, x3, y3, z3) end

---Create a new ColorRGBA color.
---@param r number Red color component (0-1).
---@param g number Green color component (0-1).
---@param b number Blue color component (0-1).
---@param a number Alpha component (0-1).
---@return ColorRGBA color The created color.
function ColorRGBA(r, g, b, a) end

---Helper for loading textures from synced assets.
Texture = {}

---Load a texture from a synced custom asset.
---Paths resolve against the synced assets, trying the raw path, then with a
---.png suffix, then under texture/. Results are cached per resolved file.
---@param path string The synced asset path, ex. "texture/icon-foo.png".
---@return TextureDescriptor? texture The loaded texture, or nil on failure.
function Texture.new(path) end

---Alias of Texture.new.
---@param path string The synced asset path.
---@return TextureDescriptor? texture The loaded texture, or nil on failure.
function Texture.loadFromFile(path) end

---Library for managing Player objects.
---players[index: integer] -> Player
---#players -> count of active players
players = {}

---Get the number of active players.
---@return integer count How many active Player objects there are.
function players.getCount() end

---Get all active players.
---@return Player[] players A list of all active Player objects.
function players.getAll() end

---Find a player by phone number.
---@param phoneNumber integer The phone identifier to search for.
---@return Player? player The found player, or nil.
function players.getByPhone(phoneNumber) end

---Get all players, excluding bots.
---@return Player[] players A list of all active non-bot Player objects.
function players.getNonBots() end

---Get all players that are bots.
---@return Player[] bots A list of all active bot Player objects.
function players.getBots() end

---Library for managing Human objects.
---humans[index: integer] -> Human
---#humans -> count of active humans
humans = {}

---Get the number of active humans.
---@return integer count How many active Human objects there are.
function humans.getCount() end

---Get all active humans.
---@return Human[] humans A list of all active Human objects.
function humans.getAll() end

---Library for managing Item objects.
---items[index: integer] -> Item
---#items -> count of active items
items = {}

---Get the number of active items.
---@return integer count How many active Item objects there are.
function items.getCount() end

---Get all active items.
---@return Item[] items A list of all active Item objects.
function items.getAll() end

---Library for managing ItemType objects.
---Includes custom item types registered by the server past the base range.
---itemTypes[index: integer] -> ItemType
---#itemTypes -> count of item types
itemTypes = {}

---Get the number of item types, including registered custom types.
---@return integer count How many ItemType objects there are.
function itemTypes.getCount() end

---Get all item types, including registered custom types.
---@return ItemType[] itemTypes A list of all ItemType objects.
function itemTypes.getAll() end

---Get an item type by its name.
---@param name string The exact name of the item type to search for. Case sensitive.
---@return ItemType? itemType The found item type, or nil.
function itemTypes.getByName(name) end

---Library for managing Vehicle objects.
---vehicles[index: integer] -> Vehicle
---#vehicles -> count of active vehicles
vehicles = {}

---Get the number of active vehicles.
---@return integer count How many active Vehicle objects there are.
function vehicles.getCount() end

---Get all active vehicles.
---@return Vehicle[] vehicles A list of all active Vehicle objects.
function vehicles.getAll() end

---Get all active vehicles that are not traffic cars.
---@return Vehicle[] vehicles A list of all active non-traffic Vehicle objects.
function vehicles.getNonTrafficCars() end

---Get all active vehicles that belong to traffic cars.
---@return Vehicle[] vehicles A list of all active traffic Vehicle objects.
function vehicles.getTrafficCars() end

---Library for managing VehicleType objects.
---Includes custom vehicle types registered by the server past the base range.
---vehicleTypes[index: integer] -> VehicleType
---#vehicleTypes -> count of vehicle types
vehicleTypes = {}

---Get the number of vehicle types, including registered custom types.
---@return integer count How many VehicleType objects there are.
function vehicleTypes.getCount() end

---Get all vehicle types, including registered custom types.
---@return VehicleType[] vehicleTypes A list of all VehicleType objects.
function vehicleTypes.getAll() end

---Get a vehicle type by its name.
---@param name string The exact name of the vehicle type to search for. Case sensitive.
---@return VehicleType? vehicleType The found vehicle type, or nil.
function vehicleTypes.getByName(name) end

---Library for managing TrafficCar objects.
---trafficCars[index: integer] -> TrafficCar
---#trafficCars -> count of traffic cars
trafficCars = {}

---Get the number of traffic cars.
---@return integer count How many TrafficCar objects there are.
function trafficCars.getCount() end

---Get all traffic cars.
---@return TrafficCar[] cars A list of all TrafficCar objects.
function trafficCars.getAll() end

---Library for accessing the game's texture slots.
---textures[index: integer] -> TextureDescriptor
---#textures -> total number of texture slots
textures = {}

---Get the total number of texture slots, valid or not.
---@return integer count How many texture slots there are.
function textures.getCount() end

---Get all texture slots, valid or not.
---@return TextureDescriptor[] textures A list of all TextureDescriptor objects.
function textures.getAll() end

---Get all texture slots that currently hold a valid texture.
---@return TextureDescriptor[] textures A list of all valid TextureDescriptor objects.
function textures.getAllValid() end

---Find a texture slot by its OpenGL texture ID.
---@param glTextureID integer The OpenGL texture name to search for.
---@return TextureDescriptor? texture The found texture, or nil.
function textures.getByGLTextureID(glTextureID) end

---Library for accessing the game's font slots.
---fonts[index: integer] -> NativeFont?
---fonts[name: string] -> NativeFont? ("vcr", "osd-white"/"osdWhite",
---"rockwell", "fixedsys", "overpass", or a renderer:loadFont name)
---#fonts -> total number of font slots
fonts = {}

---Library for managing particle emitters.
---Every created emitter is also accessible as particle[name].
particle = {}

---Create a named particle emitter, or fetch it if it already exists.
---@param name string The emitter name. Cannot be empty or "new".
---@return Particle emitter The created or existing emitter.
function particle.new(name) end

---Library for reading the in-game server browser list.
---serverListEntries[index: integer] -> ServerListEntry
serverListEntries = {}

---Get the number of server list entries.
---@return integer count How many ServerListEntry objects there are.
function serverListEntries.getCount() end

---Get the number of populated server list entries.
---@return integer count How many populated entries there are.
function serverListEntries.getPopulatedCount() end

---Get all server list entries.
---@return ServerListEntry[] entries A list of all ServerListEntry objects.
function serverListEntries.getAll() end

---Library for using generic physics functions of the engine.
physics = {}

---Get the block value at a level block position.
---@param x integer The block X coordinate.
---@param y integer The block Y coordinate.
---@param z integer The block Z coordinate.
---@return integer block The block value at that position.
function physics.getBlock(x, y, z) end

---Delete the block at a level block position.
---When connected through SRC sync, the delete is routed through the server.
---@param x integer The block X coordinate.
---@param y integer The block Y coordinate.
---@param z integer The block Z coordinate.
function physics.deleteBlock(x, y, z) end

---@class LineIntersectResult
---@field hit boolean Whether it hit. If false, all other fields will be nil.
---@field pos Vector? The global position where the ray hit.
---@field normal Vector? The normal of the surface the ray hit.
---@field fraction number? How far along the ray the hit was (0.0 - 1.0).
---@field bone integer? Which bone the ray hit, if it was cast on a human.
---@field face integer? Which face the ray hit, if not a wheel, if it was cast on a vehicle.
---@field wheel integer? Which wheel the ray hit, if not a face, if it was cast on a vehicle.

---Cast a ray in the level and find where it hits.
---@param posA Vector The start point of the ray.
---@param posB Vector The end point of the ray.
---@param onlyCity boolean Whether to only include the city (not landscape, tracks, etc).
---@return LineIntersectResult result The result of the intersection.
function physics.lineIntersectLevel(posA, posB, onlyCity) end

---Cast a ray on a single human.
---@param human Human The human to cast the ray on.
---@param posA Vector The start point of the ray.
---@param posB Vector The end point of the ray.
---@param padding number The extra padding.
---@return LineIntersectResult result The result of the intersection.
function physics.lineIntersectHuman(human, posA, posB, padding) end

---Cast a ray on a single vehicle.
---@param vehicle Vehicle The vehicle to cast the ray on.
---@param posA Vector The start point of the ray.
---@param posB Vector The end point of the ray.
---@param includeWheels boolean Whether to include wheels.
---@return LineIntersectResult result The result of the intersection.
function physics.lineIntersectVehicle(vehicle, posA, posB, includeWheels) end

---Cast a quick ray in the level and find how far along the ray it went.
---@param posA Vector The start point of the ray.
---@param posB Vector The end point of the ray.
---@param onlyCity boolean Whether to only include the city (not landscape, tracks, etc).
---@return number? fraction The fraction of the intersection, or nil if it did not hit.
function physics.lineIntersectLevelQuick(posA, posB, onlyCity) end

---Cast a quick ray on a single human.
---@param human Human The human to cast the ray on.
---@param posA Vector The start point of the ray.
---@param posB Vector The end point of the ray.
---@param padding number The extra padding.
---@return number? fraction The fraction of the intersection, or nil if it did not hit.
function physics.lineIntersectHumanQuick(human, posA, posB, padding) end

---Cast a quick ray on a single vehicle.
---@param vehicle Vehicle The vehicle to cast the ray on.
---@param posA Vector The start point of the ray.
---@param posB Vector The end point of the ray.
---@param includeWheels boolean Whether to include wheels.
---@return number? fraction The fraction of the intersection, or nil if it did not hit.
function physics.lineIntersectVehicleQuick(vehicle, posA, posB, includeWheels) end

---Cast a quick ray on the level and every human and vehicle.
---@param posA Vector The start point of the ray.
---@param posB Vector The end point of the ray.
---@param ignoreHuman Human|nil The human to ignore during the cast.
---@param humanPadding number The extra padding applied to humans.
---@param includeWheels boolean Whether to include vehicles' wheels.
---@return Human|Vehicle|nil object The nearest human or vehicle that the ray hit, or nil if it hit the level or nothing.
---@return number? fraction The fraction of the intersection, or nil if nothing was hit.
function physics.lineIntersectAnyQuick(posA, posB, ignoreHuman, humanPadding, includeWheels) end

---Library for directly reading and writing process memory.
memory = {}

---Get the base address of the game executable.
---@return integer address
function memory.getBaseAddress() end

---Get the address of a game object.
---@param object Player|Human|ItemType|Item|VehicleType|Vehicle|Bone|RigidBody|InventorySlot|Wheel|Action|MenuButton
---@return integer address
function memory.getAddress(object) end

---Read a signed 1-byte integer from memory.
---@param address integer
---@return integer value
function memory.readByte(address) end

---Read an unsigned 1-byte integer from memory.
---@param address integer
---@return integer value
function memory.readUByte(address) end

---Read a signed 2-byte integer from memory.
---@param address integer
---@return integer value
function memory.readShort(address) end

---Read an unsigned 2-byte integer from memory.
---@param address integer
---@return integer value
function memory.readUShort(address) end

---Read a signed 4-byte integer from memory.
---@param address integer
---@return integer value
function memory.readInt(address) end

---Read an unsigned 4-byte integer from memory.
---@param address integer
---@return integer value
function memory.readUInt(address) end

---Read a signed 8-byte integer from memory.
---@param address integer
---@return integer value
function memory.readLong(address) end

---Read an unsigned 8-byte integer from memory.
---@param address integer
---@return integer value
function memory.readULong(address) end

---Read a single-precision floating point number from memory.
---@param address integer
---@return number value
function memory.readFloat(address) end

---Read a double-precision floating point number from memory.
---@param address integer
---@return number value
function memory.readDouble(address) end

---Read many bytes from memory.
---@param address integer
---@param count integer The number of bytes to read.
---@return string bytes
function memory.readBytes(address, count) end

---Write a signed 1-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeByte(address, value) end

---Write an unsigned 1-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeUByte(address, value) end

---Write a signed 2-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeShort(address, value) end

---Write an unsigned 2-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeUShort(address, value) end

---Write a signed 4-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeInt(address, value) end

---Write an unsigned 4-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeUInt(address, value) end

---Write a signed 8-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeLong(address, value) end

---Write an unsigned 8-byte integer to memory.
---@param address integer
---@param value integer
function memory.writeULong(address, value) end

---Write a single-precision floating point number to memory.
---@param address integer
---@param value number
function memory.writeFloat(address, value) end

---Write a double-precision floating point number to memory.
---@param address integer
---@param value number
function memory.writeDouble(address, value) end

---Write many bytes to memory.
---@param address integer
---@param bytes string The bytes to write.
function memory.writeBytes(address, bytes) end

---Convert a 1-byte integer value into a hexadecimal string.
---@param value integer
---@return string hex
function memory.toHexByte(value) end

---Convert a 2-byte integer value into a hexadecimal string.
---@param value integer
---@return string hex
function memory.toHexShort(value) end

---Convert a 4-byte integer value into a hexadecimal string.
---@param value integer
---@return string hex
function memory.toHexInt(value) end

---Convert an 8-byte integer value into a hexadecimal string.
---@param value integer
---@return string hex
function memory.toHexLong(value) end

---Convert a 4-byte single-precision floating point value into a hexadecimal string.
---@param value number
---@return string hex
function memory.toHexFloat(value) end

---Convert an 8-byte double-precision floating point value into a hexadecimal string.
---@param value number
---@return string hex
function memory.toHexDouble(value) end

---Convert every byte in a string into a hexadecimal string.
---@param value string
---@return string hex
function memory.toHexString(value) end

---Bundled JSON library (rxi json.lua 0.1.2).
json = {}

---Encode a Lua value as a JSON string.
---@param value any The value to encode.
---@return string encoded The JSON string.
function json.encode(value) end

---Decode a JSON string into a Lua value.
---Throws on invalid JSON.
---@param str string The JSON string to decode.
---@return any value The decoded value.
function json.decode(str) end

---A value that can be sent through SRC client/server events:
---nil, boolean, number, string, or a binary blob created with blob().
---@alias SrcEventValue nil|boolean|number|string|SrcBlob

---Load and apply the config file, then run the ConfigLoaded hook.
---Provided by the core runtime (main/init.lua).
---@param fileName? string Path to the config file. Defaults to "config.yml".
function loadConfig(fileName) end

---Discover and load any newly added plugins or modes not yet loaded.
---Provided by the core runtime (main/plugins.lua).
---@return integer count The total number of newly loaded entries.
function discoverNewPlugins() end

---Register a handler for a server-to-client SRC event.
---The handler receives the decoded event arguments.
---Provided by the core runtime (main/init.lua).
---@param name string The event name.
---@param fn fun(...: SrcEventValue) The handler function.
function onServerEvent(name, fn) end

---Emit a client-to-server SRC event.
---Arguments may be nil, boolean, number, string or blob() values.
---Provided by the core runtime (main/init.lua).
---@param name string The event name.
---@param ... SrcEventValue The event arguments.
---@return boolean success Whether the event was queued for sending.
function emitServerEvent(name, ...) end

---Wrap a byte string so it is sent through events as a binary payload
---instead of a plain string.
---Provided by the core runtime (main/init.lua).
---@param bytes string The raw bytes to wrap.
---@return SrcBlob blob The wrapped binary payload.
function blob(bytes) end

---🚫 Internal. Persistent mode name supplied by the loader; consumed by
---hook.persistentMode.
---@type string
__src_persistent_mode = ""

---🚫 Internal. Emit a pre-encoded server event payload to the rs_integration
---transport. Use emitServerEvent instead.
---@param eventName string
---@param eventHash string
---@param argsBytes string
---@return boolean success
function __src_emit_server_event(eventName, eventHash, argsBytes) end

---List script paths available in the synced client script set.
---Paths are relative to scripts/, ex. "main/init.lua".
---@return string[] paths
function __src_list_scripts() end

---Read one synced script by normalized path.
---@param path string
---@return string|nil contents
function __src_read_file(path) end
