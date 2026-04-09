--# selene: allow(unused_variable)
--# selene: allow(unscoped_variables)
---@meta

---Key was just pressed this tick.
KEY_PRESSED = 2
---Key is being held down this tick.
KEY_DOWN = 1
---Key was just released this tick.
KEY_UP = 0

---The local client state. Only present on the client side.
---@type SrcLocalClient?
client = nil

---Rendering helper API exposed by the client runtime.
---@type SrcRenderer
renderer = nil

---Horizontal center alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_CENTER_X = 0x1
---Right alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_RIGHT = 0x2
---Vertical center alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_CENTER_Y = 0x4
---Bottom alignment flag for `renderer:drawTexture`.
DRAW_TEXTURE_ALIGN_BOTTOM = 0x8

---@type table<string, integer>
DrawTextureAlign = {}

---Sound helper API exposed by the client runtime.
---@type SrcSounds
sounds = nil

---@type SrcPlayersApi
players = nil

---@type SrcHumansApi
humans = nil

---@type SrcItemsApi
items = nil

---@type SrcItemTypesApi
itemTypes = nil

---@type SrcVehiclesApi
vehicles = nil

---@type SrcVehicleTypesApi
vehicleTypes = nil

---@type SrcTrafficCarsApi
trafficCars = nil

---@type SrcTexturesApi
textures = nil

---@type SrcServerListEntriesApi
serverListEntries = nil

---@type SrcPhysics
physics = nil

---@type SrcMemory
memory = nil

---@type table<string, integer>
HudAnchor = {}

---The active configuration table loaded from config.yml.
---@type table
config = {}

---Load and apply the config file, then run the ConfigLoaded hook.
---@param fileName? string Path to the config file. Defaults to "config.yml".
function loadConfig(fileName) end

---Discover and load any newly added plugins or modes not yet loaded.
---@return integer count The total number of newly loaded entries.
function discoverNewPlugins() end

---Register a handler for a server-to-client SRC event.
---@param name string The event name.
---@param fn fun(data: any, bin: string?) The handler function.
function onServerEvent(name, fn) end

---Emit a client-to-server SRC event.
---@param name string The event name.
---@param data? any JSON-serializable payload.
---@param bin? string Optional binary payload.
---@return boolean success Whether the event was sent.
function emitServerEvent(name, data, bin) end

---Current persistent mode name supplied by the loader.
---@type string
__src_persistent_mode = ""

---Emit a raw server event payload to rs_integration transport.
---@param eventName string
---@param eventHash string
---@param argsBytes string
---@return boolean success
function __src_emit_server_event(eventName, eventHash, argsBytes) end

---List script paths available in the synced client script set.
---@return string[] paths
function __src_list_scripts() end

---Read one synced script by normalized path.
---@param path string
---@return string|nil contents
function __src_read_file(path) end
