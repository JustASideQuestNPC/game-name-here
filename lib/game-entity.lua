-- Base class for all game entities to inherit from
local utils = require "lib.utils"

---@enum EntityTag
local EntityTag = {
  USES_RAW_DELTA_TIME = 0, -- Entity always recieves the raw delta time regardless of multiplier.
  USES_SCREEN_SPACE_COORDS = 1 -- Entity ignores camera position when being drawn.
}

---@class GameEntity
---@field tags EntityTag[]
---@field displayLayer integer
---@field deleted boolean
---@field markForDelete boolean
---@field update function
---@field draw function
---@field setup function
---@field delete function
---@field hasTag function

local GameEntity = {}

---Constructs a new GameEntity
---@param tags EntityTag[]?
---@param displayLayer integer?
---@return GameEntity
function GameEntity.new(tags, displayLayer)
  local entity = {}
  setmetatable(entity, {
    __index = GameEntity
  })

  entity.tags = tags or {}
  entity.displayLayer = displayLayer or 1
  entity.markForDelete = false

  return entity
end

---Called once per frame in update(), and is passed the current delta time. This base class method
---does nothing and must be overriden.
---@param dt number
function GameEntity:update(dt) end

---Called once per frame in draw(). This base class method does nothing and must be overriden.
function GameEntity:draw() end

---Called once when the entity is added to the game engine. This base class method does nothing and
---must be overriden.
function GameEntity:setup() end

---Called once when the entity is removed from the game engine at the end of an update cycle. This
---base class method does nothing and must be overriden.
function GameEntity:delete() end

---Returns whether the entity has the specified tag.
---@param tag EntityTag
---@return boolean
function GameEntity:hasTag(tag)
  return utils.arrayFind(self.tags, tag) ~= 0
end

return {
  GameEntity = GameEntity,
  EntityTag = EntityTag
}