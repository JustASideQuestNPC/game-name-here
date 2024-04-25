-- Game engine that manages all entities
local Vector2   = require "lib.vector2"
local utils     = require "lib.utils"
local config    = require "_config"
local EntityTag = require("lib.game-entity").EntityTag

-- camera tightness gets run through exp() to make the value less sensitive to tuning
local CAMERA_TIGHTNESS = math.exp(config.engine.cameraTightness)
local ROOM_WIDTH = config.gameplay.roomWidth
local ROOM_HEIGHT = config.gameplay.roomHeight
local CAMERA_MARGIN = config.engine.cameraMargin

---@type GameEntity[] All entities currently being updated and drawn.
local entities = {}
---@type table<integer, GameEntity[]> All entities, separated into their different display layers.
local displayLayers = {}
---@type integer[] Indexes of all active display layers.
local layerIndexes = {}
local cameraPos = Vector2.new(0, 0) -- The current position of the camera.
local cameraTarget = Vector2.new(0, 0) -- The position the camera is trying to reach.
local renderPos = Vector2.new(0, 0) -- Where to translate when rendering.
local deltaTimeMultiplier = 1.0 -- "Speed of time"
local lastDt = 0.0 -- Last delta time passed to `update()`

---Adds an entity to the engine, calls its `setup()` method (if it has one), then returns it.
---@param entity GameEntity
---@return GameEntity
local function addEntity(entity)
  entity.setup() -- may or may not do something
  entities[#entities+1] = entity

  -- if a display layer already exists for the entity, just add it to that layer
  if utils.arrayFind(layerIndexes, entity.displayLayer) ~= 0 then
    displayLayers[entity.displayLayer][#displayLayers[entity.displayLayer]+1] = entity

  -- otherwise, create a new layer for it
  else
    displayLayers[entity.displayLayer] = {entity}
    layerIndexes[#layerIndexes+1] = entity.displayLayer

    -- sort the index list so that layers actually get drawn in the correct order
    table.sort(layerIndexes)
  end

  return entity
end

---Removes all entities.
---@param noDelete? boolean [false] If true, entities' `delete()` methods are not called.
local function removeAll(noDelete)
  if not noDelete then
    for _, entity in ipairs(entities) do
      entity.deleted = true
      entity.delete()
    end
  end

  entities = {}
  displayLayers = {}
  layerIndexes = {}
end

---Removes all entities that a predicate function returns true for.
---@param predicate function
local function removeIf(predicate)
  local function filterFunction(entity)
    if not predicate(entity) then
      entity.deleted = true
      entity:delete() -- may or may not do something
      return false -- arrayFilter() removes items that a predicate returns *false* for
    end
    return true
  end
  entities = utils.arrayFilter(entities, filterFunction)

  -- also filter display layers
  local activeLayers = {} -- for deactivating empty layers
  for _, i in ipairs(layerIndexes) do
    displayLayers[i] = utils.arrayFilter(displayLayers[i], function(e) return not predicate(e) end)
    if #displayLayers[i] > 0 then
      activeLayers[#activeLayers+1] = i
    end
  end
  layerIndexes = activeLayers
end

---Returns an array containing all entities that a predicate function returns true for.
---@param predicate function
---@return table
local function getIf(predicate)
  return utils.arrayFilter(entities, predicate)
end

---Returns an array containing all entities that have a certain tag.
---@param tag EntityTag
---@return table
local function getTagged(tag)
  return utils.arrayFilter(entities, function (entity)
    return entity:hasTag(tag)
  end)
end

---Updates all entities. Should be called once in `love.update()` and passed the current delta time.
---@param dt number
local function update(dt)
  lastDt = dt
  -- do nothing if the entire engine is paused
  if dt == 0 then return end

  local adjustedDt = dt * deltaTimeMultiplier

  -- update all entities
  for _, entity in ipairs(entities) do
    -- skip entities that need to be deleted
    if not entity.markForDelete then
      if entity:hasTag(EntityTag.USES_RAW_DELTA_TIME) then
        entity:update(dt)
      elseif adjustedDt ~= 0 then
        entity:update(adjustedDt)
      end
    end
  end

  -- remove deleted entities
  removeIf(function (entity)
    return entity.markForDelete
  end)

  -- clamp camera position and target to within the boundary
  local xOffset = love.graphics.getWidth() / 2 - CAMERA_MARGIN
  local yOffset = love.graphics.getHeight() / 2 - CAMERA_MARGIN

  cameraPos.x = utils.clamp(cameraPos.x, xOffset, ROOM_WIDTH - xOffset)
  cameraPos.y = utils.clamp(cameraPos.y, yOffset, ROOM_HEIGHT - yOffset)
  cameraTarget.x = utils.clamp(cameraTarget.x, xOffset, ROOM_WIDTH - xOffset)
  cameraTarget.y = utils.clamp(cameraTarget.y, yOffset, ROOM_HEIGHT - yOffset)

  -- update the camera position
  cameraPos = Vector2.damp(cameraPos, cameraTarget, CAMERA_TIGHTNESS, dt)
end

---Draws all entities. Should be called once in `love.draw()`.
local function draw()
  -- find how much to translate by
  renderPos.x = -(cameraPos.x - love.graphics.getWidth() / 2)
  renderPos.y = -(cameraPos.y - love.graphics.getHeight() / 2)

  love.graphics.push()
  love.graphics.translate(renderPos.x, renderPos.y)
  for _, i in ipairs(layerIndexes) do
    local layer = displayLayers[i]
    for _, entity in ipairs(layer) do
      if entity:hasTag(EntityTag.USES_SCREEN_SPACE_COORDS) then
        love.graphics.translate(-renderPos.x, -renderPos.y)
        entity.draw()
        love.graphics.translate(renderPos.x, renderPos.y)
      else
        entity.draw()
      end
    end
  end
  love.graphics.pop()
end

---Returns a Vector2 with the current position of the camera.
---@return Vector2
---@nodiscard
local function getCameraPos()
  return cameraPos.copy()
end

---Returns a Vector2 with the current position of the camera target.
---@return Vector2
---@nodiscard
local function getCameraTarget()
  return cameraTarget.copy()
end

---Sets the position of the camera.
---@param pos Vector2
---@param noTargetUpdate? boolean [false] If true, the position of the camera target is not updated.
local function setCameraPos(pos, noTargetUpdate)
  cameraPos = pos.copy()
  if not noTargetUpdate then
    cameraTarget = pos.copy()
  end
end

---Sets the position of the camera target.
---@param pos Vector2
local function setCameraTarget(pos)
  cameraTarget = pos.copy()
end

---Converts a position in screen space (relative to the top left corner of the canvas) to a position
---in world space (relative to the position of the camera).
---@param pos Vector2
---@return Vector2
---@nodiscard
local function screenPosToWorldPos(pos)
  local converted = pos.copy()
  converted = converted - renderPos
  return converted
end

---Converts a position in world space (relative to the position of the camera) to a position in
---screen space (relative to the top left corner of the canvas).
---@param pos Vector2
---@return Vector2
---@nodiscard
local function worldPosToScreenPos(pos)
  local converted = pos.copy()
  converted = converted + renderPos
  return converted
end

---Returns the number of currently active entities.
---@return number
---@nodiscard
local function numEntities()
  return #entities
end

---Returns the current delta time, scaled to the current multiplier.
---@return number
---@nodiscard
local function deltaTime()
  return lastDt * deltaTimeMultiplier
end

---Returns the current unscaled delta time.
---@return number
---@nodiscard
local function deltaTimeRaw()
  return lastDt
end

---Returns the current delta time multiplier ("speed of time").
---@return number
---@nodiscard
local function getDeltaTimeMultiplier()
  return deltaTimeMultiplier
end

---Sets the current delta time multiplier ("speed of").
---@param m number
local function setDeltaTimeMultiplier(m)
  deltaTimeMultiplier = m
end

return {
  removeAll = removeAll,
  removeIf = removeIf,
  getIf = getIf,
  getTagged = getTagged,
  addEntity = addEntity,
  update = update,
  draw = draw,
  setCameraPos = setCameraPos,
  setCameraTarget = setCameraTarget,
  getCameraPos = getCameraPos,
  getCameraTarget = getCameraTarget,
  screenPosToWorldPos = screenPosToWorldPos,
  worldPosToScreenPos = worldPosToScreenPos,
  numEntities = numEntities,
  deltaTime = deltaTime,
  deltaTimeRaw = deltaTimeRaw,
  getDeltaTimeMultiplier = getDeltaTimeMultiplier,
  setDeltaTimeMultiplier = setDeltaTimeMultiplier
}
