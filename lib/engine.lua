-- Game engine that manages all entities
local Vector2   = require "lib.vector2"
local utils     = require "lib.utils"
local config    = require "_config"
local EntityTag = require("lib.game-entity").EntityTag

-- camera tightness gets run through exp() to make the value less sensitive to tuning
local CAMERA_TIGHTNESS = math.exp(config.engine.cameraTightness)

local entities = {} -- All entities currently being updated and drawn.
local displayLayers = {} -- All entities, separated into their different display layers.
local layerIndexes = {} -- Indexes of all active display layers.
local cameraPos = Vector2.new(0, 0) -- The current position of the camera.
local cameraTarget = Vector2.new(0, 0) -- The position the camera is trying to reach.
local renderPos = Vector2.new(0, 0) -- Where to translate when rendering.
local deltaTimeMultiplier = 1 -- "Speed of time"
local lastDt = 0 -- Last delta time passed to `update()`

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
    return entity.hasTag(tag)
  end)
end

---Updates all entities. Should be called once in `love.update()` and passed the current delta time.
---@param dt number
local function update(dt)
  lastDt = dt

  -- update all entities
  for _, entity in ipairs(entities) do
    -- skip entities that need to be deleted
    if not entity.markForDelete then
      if entity:hasTag(EntityTag.USES_RAW_DELTA_TIME) then
        entity:update(dt)
      else
        entity:update(dt * deltaTimeMultiplier)
      end
    end
  end

  -- remove deleted entities
  removeIf(function (entity)
    return entity.markForDelete
  end)

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
      if entity.hasTag(EntityTag.USES_SCREEN_SPACE_COORDS) then
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

return {
  removeAll = removeAll,
  removeIf = removeIf,
  getIf = getIf,
  getTagged = getTagged,
  addEntity = addEntity,
  update = update,
  draw = draw,
}
