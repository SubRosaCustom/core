--# selene: allow(unused_variable)
--# selene: allow(unscoped_variables)
---@meta

do
	---Represents a 3D point in the level.
	---@class Vector
	---@field class string 🔒 "Vector"
	---@field x number
	---@field y number
	---@field z number
	---@operator add(Vector):Vector
	---@operator sub(Vector):Vector
	---@operator mul(number):Vector
	---@operator mul(RotMatrix):Vector
	---@operator div(number):Vector
	---@operator unm:Vector
	local Vector

	---Add other to self.
	---@param other Vector The vector to add.
	function Vector:add(other) end

	---Multiply self by scalar.
	---@param scalar number The scalar to multiply each coordinate by.
	function Vector:mult(scalar) end

	---Replace values with those in another vector.
	---@param other Vector The vector to inherit values from.
	function Vector:set(other) end

	---Replace values with current vector × another vector.
	---@param other Vector The vector to cross with.
	function Vector:cross(other) end

	---Create a copy of self.
	---@return Vector clone The created copy.
	function Vector:clone() end

	---Calculate the distance between self and other.
	---@param other Vector The vector to calculate distance to.
	---@return number distance The distance between self and other.
	function Vector:dist(other) end

	---Calculate the distance between self and other, squared.
	---Much faster as it does not square root the value.
	---@param other Vector The vector to calculate distance to.
	---@return number distanceSquared The distance, squared.
	function Vector:distSquare(other) end

	---Calculate the length of the vector.
	---@return number length The length of the vector.
	function Vector:length() end

	---Calculate the length of the vector, squared.
	---Much faster as it does not square root the value.
	---@return number lengthSquared The length of the vector, squared.
	function Vector:lengthSquare() end

	---Calculate the dot product of self and other.
	---@param other Vector The vector to calculate the dot product with.
	---@return number dotProduct The dot product of self and other.
	function Vector:dot(other) end

	---Get the coordinates of the level block the vector is in.
	---@return integer blockX
	---@return integer blockY
	---@return integer blockZ
	function Vector:getBlockPos() end

	---Normalize the vector's values so that it has a length of 1.
	function Vector:normalize() end
end

do
	---Represents the rotation of an object as a 3x3 matrix.
	---@class RotMatrix
	---@field class string 🔒 "RotMatrix"
	---@field x1 number
	---@field y1 number
	---@field z1 number
	---@field x2 number
	---@field y2 number
	---@field z2 number
	---@field x3 number
	---@field y3 number
	---@field z3 number
	---@operator mul(RotMatrix):RotMatrix
	local RotMatrix

	---Replace values with those in another matrix.
	---@param other RotMatrix The matrix to inherit values from.
	function RotMatrix:set(other) end

	---Create a copy of self.
	---@return RotMatrix clone The created copy.
	function RotMatrix:clone() end

	---Use :rightUnit() instead. Get a normal vector pointing in the rotation's +X direction.
	---@return Vector forward The normal vector.
	---@deprecated
	function RotMatrix:getForward() end

	---Use :upUnit() instead. Get a normal vector pointing in the rotation's +Y direction.
	---@return Vector up The normal vector.
	---@deprecated
	function RotMatrix:getUp() end

	---Use :forwardUnit() instead. Get a normal vector pointing in the rotation's +Z direction.
	---@return Vector right The normal vector.
	---@deprecated
	function RotMatrix:getRight() end

	---Get a unit vector pointing in the rotation's forward (-Z) direction.
	---@return Vector forward The unit vector.
	function RotMatrix:forwardUnit() end

	---Get a unit vector pointing in the rotation's up (+Y) direction.
	---@return Vector up The unit vector.
	function RotMatrix:upUnit() end

	---Get a unit vector pointing in the rotation's right (+X) direction.
	---@return Vector right The unit vector.
	function RotMatrix:rightUnit() end
end

do
	---An RGBA color; created with ColorRGBA().
	---@class ColorRGBA
	---@field r number Red color component (0-1).
	---@field g number Green color component (0-1).
	---@field b number Blue color component (0-1).
	---@field a number Alpha component (0-1).
	local ColorRGBA
end

do
	---The local game camera; accessed through client.camera.
	---@class SrcCamera
	---@field pos Vector Position.
	---@field rot RotMatrix Rotation.
	---@field fov number Field of view.
	local SrcCamera
end

do
	---A HUD widget that only has a position.
	---@class SrcPointWidget
	---@field enabled boolean Whether the widget is drawn.
	---@field x number Offset from the anchor.
	---@field y number Offset from the anchor.
	---@field anchor integer One of the HudAnchor values.
	---@field defaultX number 🔒 The game's default offset.
	---@field defaultY number 🔒 The game's default offset.
	---@field defaultAnchor integer 🔒 The game's default anchor.
	local SrcPointWidget
end

do
	---A HUD text widget.
	---@class SrcTextWidget
	---@field enabled boolean Whether the widget is drawn.
	---@field x number Offset from the anchor.
	---@field y number Offset from the anchor.
	---@field anchor integer One of the HudAnchor values.
	---@field size number Text size.
	---@field align integer Text alignment flags.
	---@field r number Red color component (0-1).
	---@field g number Green color component (0-1).
	---@field b number Blue color component (0-1).
	---@field a number Alpha component (0-1).
	---@field defaultX number 🔒
	---@field defaultY number 🔒
	---@field defaultAnchor integer 🔒
	---@field defaultSize number 🔒
	---@field defaultAlign integer 🔒
	local SrcTextWidget
end

do
	---A HUD widget with a position and a scale.
	---@class SrcScaleWidget
	---@field enabled boolean Whether the widget is drawn.
	---@field x number Offset from the anchor.
	---@field y number Offset from the anchor.
	---@field anchor integer One of the HudAnchor values.
	---@field scale number Widget scale.
	---@field defaultX number 🔒
	---@field defaultY number 🔒
	---@field defaultAnchor integer 🔒
	---@field defaultScale number 🔒
	local SrcScaleWidget
end

do
	---The minimap HUD widget.
	---@class SrcMinimapWidget
	---@field enabled boolean Whether the minimap is drawn.
	---@field x number Offset from the anchor.
	---@field y number Offset from the anchor.
	---@field anchor integer One of the HudAnchor values.
	---@field size number Minimap size.
	---@field defaultX number 🔒
	---@field defaultY number 🔒
	---@field defaultAnchor integer 🔒
	---@field defaultSize number 🔒
	local SrcMinimapWidget
end

do
	---The progress bar HUD widget.
	---@class SrcProgressBarWidget
	---@field enabled boolean Whether the widget is drawn.
	---@field x number Offset from the anchor.
	---@field y number Offset from the anchor.
	---@field anchor integer One of the HudAnchor values.
	---@field width number Bar width.
	---@field height number Bar height.
	---@field defaultX number 🔒
	---@field defaultY number 🔒
	---@field defaultAnchor integer 🔒
	---@field defaultWidth number 🔒
	---@field defaultHeight number 🔒
	local SrcProgressBarWidget
end

do
	---The stamina bar HUD widget.
	---@class SrcStaminaBarWidget
	---@field enabled boolean Whether the widget is drawn.
	---@field x number Offset from the anchor.
	---@field y number Offset from the anchor.
	---@field anchor integer One of the HudAnchor values.
	---@field width number Bar width.
	---@field height number Bar height.
	---@field capOffsetY number Vertical offset of the bar cap.
	---@field defaultX number 🔒
	---@field defaultY number 🔒
	---@field defaultAnchor integer 🔒
	---@field defaultWidth number 🔒
	---@field defaultHeight number 🔒
	---@field defaultCapOffsetY number 🔒
	local SrcStaminaBarWidget
end

do
	---The crosshair HUD widget.
	---@class SrcCrosshairWidget
	---@field enabled boolean Whether the crosshair is drawn.
	---@field x number Offset from the anchor.
	---@field y number Offset from the anchor.
	---@field anchor integer One of the HudAnchor values.
	---@field scale number Crosshair scale.
	---@field style integer Crosshair style.
	---@field visibleWhileAiming boolean Whether the crosshair stays visible while aiming.
	---@field defaultX number 🔒
	---@field defaultY number 🔒
	---@field defaultAnchor integer 🔒
	---@field defaultScale number 🔒
	---@field defaultStyle integer 🔒
	---@field defaultVisibleWhileAiming boolean 🔒
	local SrcCrosshairWidget
end

do
	---The inventory HUD widget group.
	---@class SrcInventoryWidgets
	---@field panel SrcPointWidget
	---@field equipmentPanel SrcPointWidget
	---@field directionWidget SrcPointWidget
	local SrcInventoryWidgets
end

do
	---All repositionable HUD widgets; accessed through client.hud.
	---@class SrcHudWidgets
	---@field inventory SrcInventoryWidgets
	---@field minimap SrcMinimapWidget
	---@field crosshair SrcCrosshairWidget
	---@field staminaBar SrcStaminaBarWidget
	---@field moveModeText SrcTextWidget
	---@field chatModeText SrcTextWidget
	---@field progressBar SrcProgressBarWidget
	---@field phonePrompts SrcPointWidget
	---@field midgetWidget SrcPointWidget
	---@field messageRing SrcTextWidget
	---@field pressTabHint SrcTextWidget
	---@field moneyText SrcTextWidget
	---@field teamMoneyText SrcTextWidget
	---@field roundStartText SrcTextWidget
	---@field roundResultText SrcTextWidget
	---@field roleRevealText SrcTextWidget
	---@field saviorText SrcTextWidget
	---@field chatFeed SrcTextWidget
	---@field mapToggleHint SrcTextWidget
	local SrcHudWidgets
end

do
	---The local client state; only one instance in the global variable `client`.
	---@class SrcLocalClient
	---@field player Player? The local player, if any.
	---@field human Human? The human the local player controls, if any.
	---@field spectatingHuman Human? The human currently being spectated, if any.
	---@field camera SrcCamera 🔒 The local game camera.
	---@field isMapToggled integer Whether the fullscreen map is open.
	---@field isInGame integer Whether the client is in a game.
	---@field menuState integer The game's current menu state.
	---@field enableMouse boolean Whether the game cursor is enabled.
	---@field isTabMenu integer Whether the tab (player list) menu is open.
	---@field isPauseMenu integer 🔒 Whether the pause menu is open.
	---@field ping integer The client's ping to the current server.
	---@field isMapAutoGenerated integer Whether the map was auto-generated.
	---@field mapLegendPosX number World X of the fullscreen map legend.
	---@field mapLegendPosY number World Z of the fullscreen map legend.
	---@field serverAddress string 🔒 IPv4 address of the current server ("x.x.x.x").
	---@field serverPort integer 🔒 Port of the current server.
	---@field ticksSinceReset integer 🔒 Server ticks since the last game reset.
	---@field mouseDeltaX number Mouse yaw delta this tick, scaled by the game's mouse sensitivity.
	---@field mouseDeltaY number Mouse pitch delta this tick, scaled by the game's mouse sensitivity.
	---@field hud SrcHudWidgets 🔒 The repositionable HUD widgets.
	local SrcLocalClient
end

do
	---Represents one of the game's font slots; accessed through the fonts[] table.
	---Slots 0-4 hold the stock fonts ("vcr", "osd-white", "rockwell", "fixedsys",
	---"overpass"); later slots hold fonts loaded with renderer:loadFont.
	---@class NativeFont
	---@field class string 🔒 "NativeFont"
	---@field index integer 🔒 The index of the font slot.
	---@field name string 🔒 The font name; a stock name, or the filename stem for loaded fonts.
	---@field isValid boolean 🔒 Whether the slot currently holds a usable font.
	---@field loaded integer 🔒 Whether the slot is loaded.
	---@field atlasTexture integer 🔒 The OpenGL texture name of the glyph atlas.
	---@field cursorTexture integer 🔒
	---@field atlasWidth integer 🔒 The atlas width in pixels.
	---@field atlasHeight integer 🔒 The atlas height in pixels.
	local NativeFont
end

do
	---Rendering API exposed by the client runtime; only one instance in the
	---global variable `renderer`.
	---2D drawing uses the game's virtual 1024x576 screen space.
	---@class SrcRenderer
	---@field textFont NativeFont The font used by drawText. Must come from the fonts[] table and be loaded.
	---@field enableHead boolean Whether the first person head/body is rendered.
	---@field menu SrcRendererMenu 🔒 In-game menu widget API. Only usable inside DrawMenuItems.
	local SrcRenderer

	---Draw text on the screen.
	---Only usable inside drawing hooks such as DrawUI.
	---@param text string The text to draw.
	---@param x number Screen X position.
	---@param y number Screen Y position.
	---@param size number Text size.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	---@param params integer Text style/alignment bit flags.
	function SrcRenderer:drawText(text, x, y, size, r, g, b, a, params) end

	---Project a world position into screen space.
	---@param worldPos Vector The world position to project.
	---@param allowOffscreen boolean Whether to return positions outside the screen.
	---@return Vector? screenPos The screen position, or nil if it cannot be shown.
	function SrcRenderer:worldToScreenPosition(worldPos, allowOffscreen) end

	---Draw a filled square in screen space.
	---@param x number Screen X position.
	---@param y number Screen Y position.
	---@param size number Side length.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	function SrcRenderer:drawSquare2D(x, y, size, r, g, b, a) end

	---Draw a filled rectangle in screen space.
	---@param x number Screen X position.
	---@param y number Screen Y position.
	---@param width number Rectangle width.
	---@param height number Rectangle height.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	function SrcRenderer:drawRectangle2D(x, y, width, height, r, g, b, a) end

	---Draw a filled rectangle in screen space, rotated around its position.
	---@param x number Screen X position.
	---@param y number Screen Y position.
	---@param width number Rectangle width.
	---@param height number Rectangle height.
	---@param yaw number Rotation angle in radians.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	function SrcRenderer:drawRectangleRotated2D(x, y, width, height, yaw, r, g, b, a) end

	---Draw a circle marker on the map/minimap.
	---Only usable inside DrawMapMarkers.
	---@param x number Map-space X position.
	---@param y number Map-space Y position.
	---@param size number Circle size.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	---@param yaw number Rotation angle in radians.
	function SrcRenderer:drawMapCircle(x, y, size, r, g, b, a, yaw) end

	---Draw a 3D debug line in the world.
	---Only usable inside Draw3D.
	---@param from Vector The start point.
	---@param to Vector The end point.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	function SrcRenderer:drawDebugLine3D(from, to, r, g, b, a) end

	---Draw a 3D wireframe box in the world.
	---Only usable inside Draw3D.
	---@param pos Vector The world position of the box center.
	---@param rot RotMatrix The rotation of the box.
	---@param sizeX number Box size on the X axis.
	---@param sizeY number Box size on the Y axis.
	---@param sizeZ number Box size on the Z axis.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	function SrcRenderer:drawDebugWireBox3D(pos, rot, sizeX, sizeY, sizeZ, r, g, b, a) end

	---Draw a 3D solid box in the world.
	---Only usable inside Draw3D.
	---@param pos Vector The world position of the box center.
	---@param rot RotMatrix The rotation of the box.
	---@param sizeX number Box size on the X axis.
	---@param sizeY number Box size on the Y axis.
	---@param sizeZ number Box size on the Z axis.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	function SrcRenderer:drawDebugSolidBox3D(pos, rot, sizeX, sizeY, sizeZ, r, g, b, a) end

	---Set the color used by the debug batch primitives.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	function SrcRenderer:setDebugBatchColor(r, g, b, a) end

	---Begin batching debug primitives of a given OpenGL primitive type.
	---@param primitiveType integer The GL primitive type, ex. GL_LINES (1), GL_TRIANGLES (4).
	function SrcRenderer:beginDebugBatch(primitiveType) end

	---Add a vertex to the current debug batch.
	---@param point Vector The vertex position.
	function SrcRenderer:addDebugBatchVertex(point) end

	---Draw the current debug batch.
	function SrcRenderer:flushDebugBatch() end

	---Set the world transform applied to debug batch vertices.
	---@param pos Vector The transform position.
	---@param rot RotMatrix The transform rotation.
	function SrcRenderer:setDebugBatchTransform(pos, rot) end

	---Reset the debug batch transform back to identity.
	function SrcRenderer:resetDebugBatchTransform() end

	---Push a world transform onto the transform stack, combined with any
	---transforms already on it. Applies to subsequent 3D drawing.
	---@param pos Vector The local transform position.
	---@param rot RotMatrix The local transform rotation.
	function SrcRenderer:pushWorldTransform(pos, rot) end

	---Pop the top world transform off the transform stack.
	---Throws if the stack is empty.
	function SrcRenderer:popWorldTransform() end

	---Load a TTF font from a synced custom asset into a font slot.
	---The font name is the filename stem. Results are cached per resolved file.
	---Throws if the path does not reference a synced .ttf asset, the name is
	---already taken, or the custom font slots are exhausted.
	---@param path string The synced asset path, ex. "font/foo.ttf".
	---@return NativeFont font The loaded font.
	function SrcRenderer:loadFont(path) end

	---Unload a font previously loaded with loadFont and restore its slot.
	---Stock fonts cannot be unloaded.
	---@param font NativeFont The font to unload. Must come from the fonts[] table.
	---@return boolean unloaded Whether the font was owned by loadFont and unloaded.
	function SrcRenderer:unloadFont(font) end

	---Load a texture from a synced custom asset. Same as Texture.loadFromFile.
	---@param path string The synced asset path, ex. "texture/icon-foo.png".
	---@return TextureDescriptor? texture The loaded texture, or nil on failure.
	function SrcRenderer:loadTexture(path) end

	---Draw a texture in screen space.
	---Width/height default to the texture's own size.
	---@param texture TextureDescriptor The texture to draw. Must come from the textures[] table.
	---@param x number Screen X position.
	---@param y number Screen Y position.
	---@param width? number Drawn width.
	---@param height? number Drawn height.
	---@param r? number Red color component (0-1). Defaults to 1.
	---@param g? number Green color component (0-1). Defaults to 1.
	---@param b? number Blue color component (0-1). Defaults to 1.
	---@param a? number Alpha component (0-1). Defaults to 1.
	---@param flags? integer DRAW_TEXTURE_ALIGN_* alignment flags. Defaults to 0 (top left).
	---@return boolean drawn Whether the texture was valid and drawn.
	function SrcRenderer:drawTexture(texture, x, y, width, height, r, g, b, a, flags) end

	---Draw a texture as a quad in the current world transform space.
	---Only usable inside Draw3D; position it with pushWorldTransform.
	---@param texture TextureDescriptor The texture to draw. Must come from the textures[] table.
	---@param x number Quad X position in the current transform.
	---@param y number Quad Y position in the current transform.
	---@param width number Drawn width.
	---@param height number Drawn height.
	---@param r number Red color component (0-1).
	---@param g number Green color component (0-1).
	---@param b number Blue color component (0-1).
	---@param a number Alpha component (0-1).
	---@param flags integer DRAW_TEXTURE_ALIGN_* alignment flags; 0x80 flips vertically.
	---@return boolean drawn Whether the texture was valid and drawn.
	function SrcRenderer:drawWorldTexture(texture, x, y, width, height, r, g, b, a, flags) end

	---Draw a texture in screen space, rotated around its center.
	---@param texture TextureDescriptor The texture to draw. Must come from the textures[] table.
	---@param x number Screen X position of the center.
	---@param y number Screen Y position of the center.
	---@param width number Drawn width.
	---@param height number Drawn height.
	---@param yaw number Rotation angle in radians.
	---@param r? number Red color component (0-1). Defaults to 1.
	---@param g? number Green color component (0-1). Defaults to 1.
	---@param b? number Blue color component (0-1). Defaults to 1.
	---@param a? number Alpha component (0-1). Defaults to 1.
	---@return boolean drawn Whether the texture was valid and drawn.
	function SrcRenderer:drawTextureRotated2D(texture, x, y, width, height, yaw, r, g, b, a) end

	---Load a CMO model by name and assign it a model ID for renderObject.
	---Resolves against synced assets (data/model/) and local files. Cached per name.
	---@param name string The CMO name, ex. "foo" or "data/model/foo.cmo".
	---@return integer modelId The assigned model ID, or -1 on failure.
	function SrcRenderer:loadCMO(name) end

	---Queue a loaded CMO model to be rendered this frame.
	---Only usable inside drawing hooks such as Draw3D.
	---Models with a transparent color (a < 1) are depth-sorted and blended.
	---@param modelId integer A model ID returned by loadCMO.
	---@param worldPos Vector The world position to render at.
	---@param worldRot RotMatrix The rotation to render with.
	---@param texture? TextureDescriptor The texture to render with. Must come from the textures[] table.
	---@param color? ColorRGBA The color to tint the model with. Defaults to white.
	---@overload fun(self: SrcRenderer, modelId: integer, worldPos: Vector, worldRot: RotMatrix, color: ColorRGBA)
	function SrcRenderer:renderObject(modelId, worldPos, worldRot, texture, color) end
end

do
	---In-game menu widget API; accessed through renderer.menu.
	---Only usable inside the DrawMenuItems hook.
	---Widget layout is controlled with the nextMenuItem* fields before each call.
	---⚠️ checkbox, intSlider, floatSlider and comboBox are called with a dot
	---(renderer.menu.checkbox(...)), the rest with a colon (renderer.menu:button(...)).
	---@class SrcRendererMenu
	---@field nextMenuItemKey integer Key of the next menu item.
	---@field nextMenuItemPosX number Screen X position of the next menu item.
	---@field nextMenuItemPosY number Screen Y position of the next menu item.
	---@field nextMenuItemSizeX number Width of the next menu item.
	---@field nextMenuItemSizeY number Height of the next menu item.
	---@field checkbox fun(label: string, value: boolean): boolean, boolean Draw a checkbox. Returns the new value and whether it changed.
	---@field intSlider fun(label: string, value: integer, min: integer, max: integer): integer, boolean Draw an integer slider. Returns the new value and whether it changed.
	---@field floatSlider fun(label: string, value: number, min: number, max: number): number, boolean Draw a float slider. Returns the new value and whether it changed. Throws on platforms where it is not available yet.
	---@field comboBox fun(label: string, selectedIndex: integer, options: string[]): integer, boolean Draw a combo box. Returns the new selected index and whether it changed.
	local SrcRendererMenu

	---Draw a button.
	---@param label string The button label. Max length 255.
	---@return boolean pressed Whether the button was pressed this frame.
	function SrcRendererMenu:button(label) end

	---Draw a text input field.
	---@param label string The input label. Max length 255.
	---@param value string The current text value.
	---@param maxLength integer Maximum text length (1-255).
	---@return string value The current text after input.
	function SrcRendererMenu:textInput(label, value, maxLength) end

	---Focus the next menu item.
	function SrcRendererMenu:focusNext() end
end

do
	---Sound API exposed by the client runtime; only one instance in the global
	---variable `sounds`.
	---@class SrcSounds
	local SrcSounds

	---Load a WAV sound from a synced custom asset into a sound slot.
	---Paths resolve against the synced assets, trying the raw path, then with a
	---.wav suffix, then under sound/.
	---@param path string The synced asset path, ex. "sound/foo.wav".
	---@param maxDistance? number The maximum audible distance factor. Defaults to 1.0.
	---@return integer soundId The loaded sound slot, or -1 on failure.
	function SrcSounds:loadSound(path, maxDistance) end

	---Play a loaded sound at a world position.
	---@param soundId integer A sound slot returned by loadSound.
	---@param position Vector The world position to play at.
	---@param volume? number The volume, where 1.0 is standard.
	---@param pitch? number The pitch, where 1.0 is standard.
	---@return integer emitterId The emitter playing the sound, or -1 if it could not be determined.
	function SrcSounds:playSound3D(soundId, position, volume, pitch) end

	---Stop a playing sound emitter.
	---@param emitterId integer An emitter ID returned by playSound3D.
	function SrcSounds:stopSound(emitterId) end
end

do
	---A named particle emitter created with particle.new.
	---Types 1 (blood), 2 (puff) and 5 (trail) spawn native game particles;
	---type 6 (sprite) spawns custom textured billboards and requires a texture.
	---Setters validate their values and throw on out-of-range input.
	---@class Particle
	---@field type integer The particle type. 1 = blood, 2 = puff, 5 = trail, 6 = sprite.
	---@field lifeTime number Lifetime in seconds. Must be positive.
	---@field startSize number World size at spawn. Must be positive.
	---@field endSize number World size at end of life (sprite only). Must be positive.
	---@field gravity number Vertical acceleration added to the velocity per tick.
	---@field damping number Velocity multiplier applied per tick. Cannot be negative.
	---@field rotation number Sprite rotation in radians.
	---@field rotationSpeed number Sprite rotation speed in radians per second.
	---@field blend integer Sprite blend mode. 0 = alpha, 1 = additive.
	---@field maxParticles integer Per-emitter live sprite cap, 1-2048.
	---@field texture TextureDescriptor? The sprite texture. Must come from the textures[] table.
	---@field red number Red color component (0-1). Sprite only.
	---@field green number Green color component (0-1). Sprite only.
	---@field blue number Blue color component (0-1). Sprite only.
	---@field alpha number Alpha component (0-1). Sprite only.
	local Particle

	---Emit particles from this emitter.
	---For trail particles (type 5), position is the trail end point and
	---velocity is required as the trail start point.
	---@param position Vector The world position to spawn at.
	---@param velocity? Vector The initial velocity. Required for trails.
	---@param count? integer How many particles to emit. Defaults to 1.
	---@return integer emitted How many particles were emitted after capacity limits.
	function Particle:emit(position, velocity, count) end
end

do
	---A binary payload for SRC events, created with blob().
	---Offsets are 1-based. Readers return nil when out of range.
	---#blob -> size in bytes
	---@class SrcBlob
	local SrcBlob

	---Get the size of the payload in bytes.
	---@return integer size
	function SrcBlob:size() end

	---Get a copy of the raw bytes.
	---@param offset? integer The 1-based start offset. Defaults to 1.
	---@param count? integer How many bytes to read. Defaults to the rest.
	---@return string? bytes The bytes, or nil if the range is invalid.
	function SrcBlob:bytes(offset, count) end

	---Alias of bytes.
	---@param offset? integer The 1-based start offset. Defaults to 1.
	---@param count? integer How many bytes to read. Defaults to the rest.
	---@return string? bytes The bytes, or nil if the range is invalid.
	function SrcBlob:sub(offset, count) end

	---Read a signed 1-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readByte(offset) end

	---Read an unsigned 1-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readUByte(offset) end

	---Read a signed big-endian 2-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readShort(offset) end

	---Read an unsigned big-endian 2-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readUShort(offset) end

	---Read a signed big-endian 4-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readInt(offset) end

	---Read an unsigned big-endian 4-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readUInt(offset) end

	---Read a signed big-endian 8-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readLong(offset) end

	---Read an unsigned big-endian 8-byte integer.
	---@param offset integer The 1-based offset.
	---@return integer? value
	function SrcBlob:readULong(offset) end

	---Read a big-endian single-precision float.
	---@param offset integer The 1-based offset.
	---@return number? value
	function SrcBlob:readFloat(offset) end

	---Read a big-endian double-precision float.
	---@param offset integer The 1-based offset.
	---@return number? value
	function SrcBlob:readDouble(offset) end
end

---Represents a networked action sent from a player.
---⚠️ Opaque on the client; its fields are not exposed by the runtime yet.
---@class Action

---Represents a button in the world base menu.
---⚠️ Opaque on the client; its fields are not exposed by the runtime yet.
---@class MenuButton

do
	---Represents a player in the current game, who may or may not be spawned in.
	---@class Player
	---@field class string 🔒 "Player"
	---@field data table A Lua table which persists for the lifespan of the runtime.
	---@field index integer 🔒 The index of the array in memory this is.
	---@field isActive boolean Whether this exists, only change if you know what you are doing.
	---@field name string Nickname of this player.
	---@field subRosaID integer Unique account index given by the master server.
	---@field phoneNumber integer Unique public ID tied to the account, ex. 2560001.
	---@field money integer
	---@field teamMoney integer The value of their team's balance in world mode.
	---@field budget integer The value of their team's budget in world mode.
	---@field corporateRating integer
	---@field criminalRating integer
	---@field itemsBought integer Decreases slowly over time; used to limit items bought.
	---@field vehiclesBought integer Decreases slowly over time; used to limit vehicles bought.
	---@field withdrawnBills integer Decreases slowly over time; used to limit money withdrawn.
	---@field team integer
	---@field teamSwitchTimer integer Ticks remaining until they can switch teams again.
	---@field stocks integer The amount of shares they own in their company.
	---@field spawnTimer integer How long this person has to wait to spawn in, in seconds.
	---@field gearX number Left to right stick shift position, 0 to 2.
	---@field leftRightInput number Left to right movement input, -1 to 1.
	---@field gearY number Forward to back stick shift position, -1 to 1.
	---@field forwardBackInput number Backward to forward movement input, -1 to 1.
	---@field viewYaw number Radians.
	---@field viewYawDelta number Radians.
	---@field viewPitch number Radians.
	---@field viewPitchDelta number Radians.
	---@field freeLookYaw number Radians.
	---@field freeLookPitch number Radians.
	---@field realViewYaw number Radians.
	---@field realViewPitch number Radians.
	---@field inputFlags integer Bit flags of current buttons being pressed.
	---@field lastInputFlags integer Input flags from the last tick.
	---@field controllerModeGear integer
	---@field zoomLevel integer 0 = run, 1 = walk, 2 = aim.
	---@field inputType integer What the input fields are used for. 0 = none, 1 = human, 2 = car, 3 = helicopter.
	---@field menuTab integer What tab in the menu they are currently in.
	---@field numActions integer
	---@field lastNumActions integer
	---@field numMenuButtons integer
	---@field gender integer 0 = female, 1 = male.
	---@field skinColor integer Starts at 0.
	---@field hairColor integer
	---@field hair integer
	---@field eyeColor integer
	---@field model integer 0 = casual, 1 = suit.
	---@field head integer
	---@field suitColor integer
	---@field tieColor integer 0 = no tie, 1 = the first color.
	---@field necklace integer
	---@field isAdmin boolean
	---@field isSpeaking boolean Whether their voice is currently transmitting.
	---@field isReady boolean Whether they are readied up on the pre-game screen.
	---@field isGodMode boolean
	---@field isBot boolean
	---@field isZombie boolean Whether the bot should always run towards its target.
	---@field human Human? The human they currently control.
	---@field botDestination Vector? The location this bot will walk towards.
	local Player

	---Get a specific action.
	---@param index integer The index between 0 and 63.
	---@return Action action The desired action.
	function Player:getAction(index) end

	---Get a specific menu button.
	---@param index integer The index between 0 and 31.
	---@return MenuButton menuButton The desired menu button.
	function Player:getMenuButton(index) end
end

do
	---Represents a human, including dead bodies.
	---@class Human
	---@field class string 🔒 "Human"
	---@field data table A Lua table which persists for the lifespan of the runtime.
	---@field index integer 🔒 The index of the array in memory this is.
	---@field isActive boolean Whether this exists, only change if you know what you are doing.
	---@field stamina integer
	---@field maxStamina integer
	---@field vehicleSeat integer Seat index of the vehicle they are in.
	---@field despawnTime integer Ticks remaining until removal if dead.
	---@field spawnProtection integer Ticks of protection from damage remaining.
	---@field movementState integer 0 = normal, 1 = in midair, 2 = sliding, rest unknown.
	---@field zoomLevel integer 0 = run, 1 = walk, 2 = aim.
	---@field throwPitch number Current pitch of item being thrown. Radians.
	---@field damage integer Level of screen blackness, 0-60.
	---@field pos Vector Position.
	---@field viewYaw number Radians.
	---@field viewPitch number Radians.
	---@field viewYaw2 number Radians.
	---@field viewPitch2 number Radians.
	---@field strafeInput number Left to right movement input, -1 to 1.
	---@field walkInput number Backward to forward movement input, -1 to 1.
	---@field inputFlags integer Bit flags of current buttons being pressed.
	---@field lastInputFlags integer Input flags from the last tick.
	---@field numChatMessages integer
	---@field health integer Dynamic health, 0-100.
	---@field bloodLevel integer How much blood they have, 0-100. <50 and they will collapse.
	---@field chestHP integer Dynamic chest health, 0-100.
	---@field headHP integer
	---@field leftArmHP integer
	---@field rightArmHP integer
	---@field leftLegHP integer
	---@field rightLegHP integer
	---@field progressBar integer Progress bar displayed in the center of the screen, 0-255. 0 = disabled.
	---@field inventoryAnimationFlags integer
	---@field inventoryAnimationProgress number
	---@field inventoryAnimationDuration integer
	---@field inventoryAnimationHand integer
	---@field inventoryAnimationSlot integer
	---@field inventoryAnimationCounterFinished integer
	---@field inventoryAnimationCounter integer
	---@field gender integer See Player.gender.
	---@field head integer See Player.head.
	---@field skinColor integer See Player.skinColor.
	---@field hairColor integer See Player.hairColor.
	---@field hair integer See Player.hair.
	---@field eyeColor integer See Player.eyeColor.
	---@field model integer See Player.model.
	---@field suitColor integer See Player.suitColor.
	---@field tieColor integer See Player.tieColor.
	---@field necklace integer See Player.necklace.
	---@field lastUpdatedWantedGroup integer 0 = white, 1 = yellow, 2 = red.
	---@field isAlive boolean
	---@field isImmortal boolean Whether they are immune to bullet and physics damage.
	---@field isOnGround boolean 🔒
	---@field isStanding boolean 🔒
	---@field isBleeding boolean
	---@field player Player? The player controlling this human.
	---@field vehicle Vehicle? The vehicle they are inside.
	local Human

	---Teleport to a different position by offsetting every bone and rigid body.
	---@param position Vector The position to teleport to.
	function Human:teleport(position) end

	---Get a specific bone.
	---@param index integer The index between 0 and 15.
	---@return Bone bone The desired bone.
	function Human:getBone(index) end

	---Get the rigid body of a specific bone.
	---@param index integer The index between 0 and 15.
	---@return RigidBody rigidBody The desired rigid body.
	function Human:getRigidBody(index) end

	---Get a specific inventory slot.
	---@param index integer The index between 0 and 6.
	---@return InventorySlot inventorySlot The desired inventory slot.
	function Human:getInventorySlot(index) end

	---Set the velocity of every rigid body.
	---@param velocity Vector The velocity to set.
	function Human:setVelocity(velocity) end

	---Add velocity to every rigid body.
	---@param velocity Vector The velocity to add.
	function Human:addVelocity(velocity) end
end

do
	---Represents a bone in a human.
	---@class Bone
	---@field class string 🔒 "Bone"
	---@field rigidBody RigidBody 🔒 The rigid body simulating this bone.
	---@field pos Vector Position.
	---@field pos2 Vector Second position.
	---@field vel Vector Velocity.
	---@field rot RotMatrix Rotation.
	---@field mass number In kilograms, kind of.
	---@field scale Vector
	---@field scaleReciprocal Vector
	---@field smallestScaleFactor number
	local Bone
end

do
	---Represents an inventory slot of a human.
	---@class InventorySlot
	---@field class string 🔒 "InventorySlot"
	---@field count integer Amount of items in the slot.
	---@field primaryItem Item? 🔒 The first item in the slot, if any.
	---@field secondaryItem Item? 🔒 The second item in the slot, if any.
	local InventorySlot
end

do
	---Represents a rigid body currently in use by the physics engine.
	---@class RigidBody
	---@field class string 🔒 "RigidBody"
	---@field data table A Lua table which persists for the lifespan of the runtime.
	---@field index integer 🔒 The index of the array in memory this is.
	---@field isActive boolean Whether this exists, only change if you know what you are doing.
	---@field type integer 0 = bone, 1 = car body, 2 = wheel, 3 = item.
	---@field linkedHumanOrItemID integer The index of the human or item linked to this body.
	---@field localIndex integer The bone index this body belongs to, if any.
	---@field mass number In kilograms, kind of.
	---@field pos Vector Position.
	---@field vel Vector Velocity.
	---@field rot RotMatrix Rotation.
	---@field rotVel RotMatrix Rotational velocity.
	---@field scale Vector
	---@field scaleReciprocal Vector
	---@field smallestScaleFactor number
	---@field unused Vector
	---@field vehicleDebugBoxSize Vector
	---@field suspensionRelated number
	---@field isSettled boolean Whether this rigid body is settled by gravity.
	local RigidBody

	---⚠️ Not implemented in the SRC client runtime; currently returns nil.
	---@param otherBody RigidBody The second body in the bond.
	---@param thisLocalPos Vector The local position relative to this body.
	---@param otherLocalPos Vector The local position relative to the other body.
	---@return nil
	function RigidBody:bondTo(otherBody, thisLocalPos, otherLocalPos) end

	---⚠️ Not implemented in the SRC client runtime; currently returns nil.
	---@param otherBody RigidBody The second body in the bond.
	---@return nil
	function RigidBody:bondRotTo(otherBody) end

	---⚠️ Not implemented in the SRC client runtime; currently returns nil.
	---@param localPos Vector The local position relative to this body.
	---@param globalPos Vector The global position in the level.
	---@return nil
	function RigidBody:bondToLevel(localPos, globalPos) end

	---⚠️ Not implemented in the SRC client runtime; currently does nothing.
	---@param localPos Vector The local position relative to this body.
	---@param normal Vector The normal of the collision.
	---@param a number
	---@param b number
	---@param c number
	---@param d number
	function RigidBody:collideLevel(localPos, normal, a, b, c, d) end
end

do
	---Represents an item in the world or someone's inventory.
	---@class Item
	---@field class string 🔒 "Item"
	---@field data table A Lua table which persists for the lifespan of the runtime.
	---@field index integer 🔒 The index of the array in memory this is.
	---@field isActive boolean Whether this exists, only change if you know what you are doing.
	---@field type ItemType
	---@field despawnTime integer Ticks remaining until removal.
	---@field physicsSettledTimer integer How many ticks the item has been settling.
	---@field parentSlot integer The slot this item occupies if it has a parent.
	---@field parentHuman Human? The human this item is mounted to, if any.
	---@field parentItem Item? The item this item is mounted to, if any.
	---@field pos Vector Position.
	---@field interpPos Vector 🔒 Interpolated render position.
	---@field interpRot RotMatrix 🔒 Interpolated render rotation.
	---@field vel Vector Velocity.
	---@field rot RotMatrix Rotation.
	---@field bullets integer How many bullets are inside this item.
	---@field numChildItems integer How many child items are linked to this item.
	---@field cooldown integer
	---@field numChatMessages integer
	---@field muzzleFlashTimer integer Ticks remaining on the muzzle flash effect.
	---@field cashSpread integer
	---@field cashAmount integer
	---@field cashPureValue integer
	---@field phoneNumber integer The number used to call this phone.
	---@field callerRingTimer integer
	---@field displayPhoneNumber integer The number currently displayed on the phone.
	---@field enteredPhoneNumber integer The number that has been entered on the phone.
	---@field phoneTexture integer The phone's texture ID. 0 for white, 1 for black.
	---@field phoneStatus integer The status of the phone.
	---@field computerCurrentLine integer
	---@field computerTopLine integer Which line is at the top of the screen.
	---@field computerCursor integer The location of the cursor, -1 for no cursor.
	---@field memoText string The memo/newspaper text of the item. ⚠️ The setter is not implemented in the client runtime yet; assignment does nothing.
	---@field hasPhysics boolean Whether this item is currently physically simulated.
	---@field physicsSettled boolean Whether this item is settled by gravity.
	---@field isStatic boolean Whether the item is immovable.
	---@field isInPocket boolean Whether the item is in someone's inventory.
	---@field rigidBody RigidBody 🔒 The rigid body representing the physics of this item.
	---@field connectedPhone Item? The phone that this phone is connected to.
	---@field vehicle Vehicle? The vehicle which this item is a key for.
	---@field grenadePrimer Player? The player who primed this grenade.
	local Item

	---Get one of the item's child items. Ex. a magazine in a gun.
	---@param index integer Which child item to fetch, between 0 and numChildItems-1.
	---@return Item childItem The fetched child item.
	function Item:getChildItem(index) end

	---Set the text to display on a line. Only works if this item is a computer.
	---@param lineIndex integer Which line to edit, between 0 and 31.
	---@param text string The text to set the line to. Max 63 characters.
	function Item:computerSetLine(lineIndex, text) end

	---Set the colors to display on a line. Only works if this item is a computer.
	---@param lineIndex integer Which line to edit, between 0 and 31.
	---@param colors string The colors to set, where every character is a color value from 0x00 to 0xFF. Max 63 characters.
	function Item:computerSetLineColors(lineIndex, colors) end

	---Set the color of a character on screen. Only works if this item is a computer.
	---Uses the 16 CGA colors for foreground and background separately.
	---@param lineIndex integer Which line to edit, between 0 and 31.
	---@param columnIndex integer Which column to edit, between 0 and 63.
	---@param color integer The color to set, between 0x00 and 0xFF.
	function Item:computerSetColor(lineIndex, columnIndex, color) end
end

do
	---Represents a type of item that exists.
	---Custom types past the base range can be registered by the server.
	---@class ItemType
	---@field class string 🔒 "ItemType"
	---@field index integer 🔒 The index of the array in memory this is.
	---@field name string
	---@field price integer How much money is taken when bought.
	---@field mass number In kilograms, kind of.
	---@field fireRate integer How many ticks between two shots.
	---@field magazineAmmo integer
	---@field bulletType integer
	---@field bulletVelocity number
	---@field bulletSpread number
	---@field numHands integer
	---@field rightHandPos Vector
	---@field leftHandPos Vector
	---@field primaryGripStiffness number
	---@field primaryGripRotation number In radians.
	---@field secondaryGripStiffness number
	---@field secondaryGripRotation number In radians.
	---@field boundsCenter Vector
	---@field gunHoldingPos Vector The offset of where the item is held if it is a gun.
	---@field isGun boolean
	local ItemType

	---Get whether this type can be mounted to another type.
	---@param parent ItemType The parent item type.
	---@return boolean canMount
	function ItemType:getCanMountTo(parent) end

	---Set whether this type can be mounted to another type.
	---@param parent ItemType The parent item type.
	---@param canMount boolean
	function ItemType:setCanMountTo(parent, canMount) end
end

do
	---Represents a car, train, or helicopter.
	---@class Vehicle
	---@field class string 🔒 "Vehicle"
	---@field data table A Lua table which persists for the lifespan of the runtime.
	---@field index integer 🔒 The index of the array in memory this is.
	---@field isActive boolean Whether this exists, only change if you know what you are doing.
	---@field type VehicleType
	---@field controllableState integer 0 = cannot be controlled, 1 = car, 2 = helicopter.
	---@field health integer 0-100.
	---@field color integer 0 = black, 1 = red, 2 = blue, 3 = silver, 4 = white, 5 = gold.
	---@field despawnTime integer Ticks remaining until removal. -1 for never.
	---@field isLocked boolean Whether this has a key and is locked.
	---@field pos Vector Position.
	---@field pos2 Vector Secondary position value.
	---@field interpPos Vector 🔒 Interpolated render position.
	---@field interpRot RotMatrix 🔒 Interpolated render rotation.
	---@field rot RotMatrix Rotation.
	---@field vel Vector Velocity.
	---@field gearX number Left to right stick shift position, 0 to 2.
	---@field steerControl number Left to right wheel position, -0.75 to 0.75.
	---@field gearY number Forward to back stick shift position, -1 to 1.
	---@field gasControl number Brakes to full gas, -1 to 1.
	---@field engineRPM integer The RPM of the engine, 0 to 8191.
	---@field bladeBodyID integer The rigid body index of the helicopter blades.
	---@field numSeats integer The number of accessible seats.
	---@field numWheels integer The number of wheels.
	---@field lastDriver Player? 🔒 The last person to drive the vehicle.
	---@field rigidBody RigidBody 🔒 The rigid body representing the physics of this vehicle.
	---@field trafficCar TrafficCar? The traffic car the vehicle belongs to.
	local Vehicle

	---Get whether a specific window is broken.
	---@param index integer The index between 0 and 7.
	---@return boolean isWindowBroken
	function Vehicle:getIsWindowBroken(index) end

	---Set whether a specific window is broken.
	---@param index integer The index between 0 and 7.
	---@param isWindowBroken boolean
	function Vehicle:setIsWindowBroken(index, isWindowBroken) end

	---Get a wheel on the vehicle.
	---@param index integer The index between 0 and 6; only 0 to numWheels-1 are meaningful.
	---@return Wheel wheel The desired wheel.
	function Vehicle:getWheel(index) end
end

do
	---Represents a type of vehicle that exists.
	---Custom types past the base range can be registered by the server.
	---@class VehicleType
	---@field class string 🔒 "VehicleType"
	---@field index integer 🔒 The index of the array in memory this is.
	---@field name string
	---@field controllableState integer 0 = cannot be controlled, 1 = car, 2 = helicopter.
	---@field price integer How much money is taken when bought.
	---@field mass number In kilograms, kind of.
	---@field acceleration number How fast the vehicle can accelerate.
	---@field numWheels integer How many wheels this vehicle has.
	---@field numSeats integer How many seats this vehicle has.
	---@field usesExternalModel boolean 🔒
	local VehicleType
end

do
	---Represents an AI traffic car.
	---@class TrafficCar
	---@field class string 🔒 "TrafficCar"
	---@field index integer 🔒 The index of the array in memory this is.
	---@field type VehicleType The type of the car.
	---@field pos Vector Position.
	---@field vel Vector Velocity.
	---@field yaw number Radians.
	---@field rot RotMatrix Rotation.
	---@field color integer The color of the car.
	---@field state integer
	---@field human Human? The human driving the car.
	---@field isBot boolean
	---@field isAggressive boolean
	---@field vehicle Vehicle? The real vehicle used by the car.
	local TrafficCar
end

do
	---Represents a wheel on a car, train, or helicopter.
	---@class Wheel
	---@field class string 🔒 "Wheel"
	---@field spin number The spin constant of the wheel.
	---@field visualHeight number The height of the wheel.
	---@field vehicleHeight number The height of the vehicle.
	---@field skid number The skid constant of the wheel.
	---@field rigidBody RigidBody? 🔒 The rigid body representing the physics of this wheel.
	local Wheel
end

do
	---Represents one of the game's texture slots.
	---@class TextureDescriptor
	---@field class string 🔒 "TextureDescriptor"
	---@field index integer 🔒 The index of the texture slot.
	---@field width integer The width in pixels.
	---@field height integer The height in pixels.
	---@field mipLevels integer
	---@field internalFormat integer
	---@field pixelFormat integer
	---@field wrapS integer
	---@field wrapT integer
	---@field minFilter integer
	---@field magFilter integer
	---@field unknown24 integer
	---@field flags integer
	---@field glTextureID integer The OpenGL texture name.
	---@field isValid boolean 🔒 Whether the slot currently holds a usable texture.
	local TextureDescriptor
end

do
	---Represents an entry in the in-game server browser list.
	---@class ServerListEntry
	---@field class string 🔒 "ServerListEntry"
	---@field index integer 🔒 The index of the array in memory this is.
	---@field versionMajor integer
	---@field versionMinor integer
	---@field networkVersion integer
	---@field name string The server name.
	---@field srkIdentifier integer
	---@field port integer
	---@field ping integer
	---@field gameType integer
	---@field isPassworded boolean
	---@field playerCount integer
	---@field maxPlayerCount integer
	---@field ip string 🔒 IPv4 address ("x.x.x.x").
	local ServerListEntry
end
