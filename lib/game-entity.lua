-- Base class for all game entities to inherit from

---@class GameEntity
---@field tags table
---@field killMe boolean
---@field update function
---@field draw function
---@field hasTag function

local GameEntity = {}

-- Constructor
function GameEntity.new()
    local e = {}
    -- setmetatable
end


return GameEntity