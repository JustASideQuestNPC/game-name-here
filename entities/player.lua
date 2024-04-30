-- Player character.

local config  = require "_config"
local utils   = require "lib.utils"
local input   = require "lib.input-manager"
local Vector2 = require "lib.vector2"
local engine  = require "lib.engine"
local Sprite  = require "lib.sprite"
local temp    = require "lib.game-entity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

local INVERT_THUMBSTICKS = config.input.invertThumbsticks

---@class Player: GameEntity
---@field RUN_SPEED number normal running speed in pixels per second
---@field DASH_SPEED number dash speed in pixels per second
---@field DASH_DURATION number dash duration in seconds
---@field MAX_CONSECUTIVE_DASHES integer how many dashes can be performed in quick succession
---@field DASH_REFRESH_DURATION number how many seconds before all dashes are replenished
---@field sprite Sprite
---@field position Vector2
---@field velocity Vector2
---@field angle number
---@field remainingDashes integer
---@field dashTimer number
---@field dashRefreshTimer number
---@field new fun(x: number, y: number): Player
---@field update fun(self, dt: number)
---@field draw fun(self)
---@field beginDash fun(self, dashVector: Vector2)
local Player = utils.class(
  GameEntity, function (instance, x, y)
    instance.tags = {EntityTag.PLAYER}
    instance.displayLayer = -1

    instance.RUN_SPEED = config.entities.player.runSpeed
    instance.DASH_SPEED = config.entities.player.dashSpeed
    instance.DASH_DURATION = config.entities.player.dashDuration
    instance.MAX_CONSECUTIVE_DASHES = config.entities.player.maxConsecutiveDashes
    instance.DASH_REFRESH_DURATION = config.entities.player.dashRefreshDuration

    instance.sprite = Sprite("player")

    instance.position = Vector2(x, y)
    instance.velocity = Vector2(0, 0)
    instance.angle = 0

    instance.remainingDashes = instance.MAX_CONSECUTIVE_DASHES
    instance.dashTimer = 0
    instance.dashRefreshTimer = 0
  end
)

function Player:draw()
  love.graphics.push()
  love.graphics.translate(self.position.x, self.position.y)
  love.graphics.rotate(self.angle + math.pi / 2)

  self.sprite:draw(0, 0)

  love.graphics.pop()
end

function Player:update(dt)
  -- move at the beginning of the update to prevent some issues with collisions
  self.position = self.position + self.velocity * dt
  engine.setCameraTarget(self.position)

  -- find aim direction
  if input.currentInputType() == "gamepad" then
    local lookVector
    if INVERT_THUMBSTICKS then
      lookVector = input.getStickVector("left")
    else
      lookVector = input.getStickVector("right")
    end

    -- prevents a lot of weird and unfun control issues
    if lookVector:magSq() > 0.9 then
      self.angle = lookVector:angle()
    end

  else
    local mpos = engine.screenPosToWorldPos(input.getMousePos())
    local delta = mpos - self.position
    self.angle = delta:angle()
  end

  -- if we're dashing, ignore movement input and update the timer
  if self.dashTimer > 0 then
    self.dashTimer = self.dashTimer - dt
    self.dashRefreshTimer = self.DASH_REFRESH_DURATION
  else
    -- refresh dashes
    if self.dashRefreshTimer > 0 then
      self.dashRefreshTimer = self.dashRefreshTimer - dt
      if self.dashRefreshTimer <= 0 then
        self.remainingDashes = self.MAX_CONSECUTIVE_DASHES
      end
    end

    -- find what direction we're moving
    local moveDir
    if input.currentInputType() == "gamepad" then
      if INVERT_THUMBSTICKS then
        moveDir = input.getStickVector("right")
      else
        moveDir = input.getStickVector("left")
      end
    else
      moveDir = input.getDpadVector("move up", "move down", "move left", "move right")
    end

    -- update velocity
    if moveDir:magSq() > 0 then
      self.velocity = moveDir
      if input.isActive("dash") and self.remainingDashes > 0 then
        self:beginDash(moveDir)
      else
        self.velocity = moveDir * self.RUN_SPEED
      end
    else
      -- has the same effect as setting x and y to 0
      self.velocity = Vector2()
    end
  end
end

function Player:beginDash(dashVector)
  self.remainingDashes = self.remainingDashes - 1

  self.velocity = dashVector:setMag(self.DASH_SPEED)
  self.dashTimer = self.DASH_DURATION
end

return Player