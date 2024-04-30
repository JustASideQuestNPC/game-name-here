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
local MELEE_COMBO_LENGTH = config.entities.player.meleeComboLength
local MELEE_JAB_ANGLE_SIZE = math.rad(config.entities.player.meleeJabAngleSize)
local MELEE_SPIN_END_LAG = config.entities.player.meleeSpinEndLag

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
---@field meleeTrailPoints table[]
---@field meleeHitboxAngle number
---@field meleeAngleOffset number
---@field meleeEndAngle number
---@field meleeCooldown number
---@field meleeComboResetTime number
---@field isMeleeing boolean
---@field meleeSwipeDirection integer
---@field meleeComboPosition integer
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

    instance.meleeTrailPoints = {}
    instance.meleeHitboxAngle = 0
    instance.meleeAngleOffset = 0
    instance.meleeEndAngle = 0
    instance.meleeCooldown = 0
    instance.meleeComboResetTime = 0
    instance.isMeleeing = false
    instance.meleeSwipeDirection = 1
    instance.meleeComboPosition = 0
  end
)

function Player:draw()
  love.graphics.push()
  love.graphics.translate(self.position.x, self.position.y)
  love.graphics.rotate(self.angle + math.pi / 2)

  self.sprite:draw(0, 0)

  -- draw melee positions
  love.graphics.rotate(-(self.angle + math.pi / 2))
  for _, pt in pairs(self.meleeTrailPoints) do
    love.graphics.setColor(love.math.colorFromBytes(133, 218, 235,
        utils.map(pt.time, 0, 0.2, 0, 255)))
    love.graphics.circle("fill", pt.position.x, pt.position.y, utils.map(pt.time, 0, 0.2, 0, 10))
  end

  love.graphics.pop()
end

function Player:update(dt)
  -- move at the beginning of the update to prevent some issues with collisions
  self.position = self.position + self.velocity * dt
  engine.setCameraTarget(self.position)

  -- find aim direction
  local setAngleFromMovement = false
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
    else
      setAngleFromMovement = true
    end

  else
    local mpos = engine.screenPosToWorldPos(input.getMousePos())
    local delta = mpos - self.position
    self.angle = delta:angle()
  end

  -- if we're dashing, ignore control input and update the timer
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

    if setAngleFromMovement and moveDir:magSq() > 0 then
      self.angle = moveDir:angle()
    end

    -- check for attack inputs
    if input.isActive("melee") and self.meleeCooldown <= 0 and not self.isMeleeing then
      self.isMeleeing = true
      self.meleeAngleOffset = self.angle

      self.meleeComboPosition = self.meleeComboPosition + 1
      self.meleeSwipeDirection = self.meleeSwipeDirection * -1
      -- if this is the last attack in the combo, do a spin attack
      if self.meleeComboPosition == MELEE_COMBO_LENGTH then
        self.meleeHitboxAngle = -((MELEE_JAB_ANGLE_SIZE / 2) * self.meleeSwipeDirection)
        self.meleeEndAngle = math.pi * 2 * self.meleeSwipeDirection - self.meleeHitboxAngle
      -- otherwise, do a fast jab
      else
        self.meleeEndAngle = (MELEE_JAB_ANGLE_SIZE / 2) * self.meleeSwipeDirection
        self.meleeHitboxAngle = -self.meleeEndAngle
      end
    end
  end

  if self.meleeCooldown > 0 then
    self.meleeCooldown = self.meleeCooldown - dt
    if self.meleeCooldown <= 0 then
      self.meleeSwipeDirection = 1
      self.meleeComboPosition = 0
    end
  end

  -- update melee attack
  if self.isMeleeing then
    local step = (math.pi * 4 * dt * self.meleeSwipeDirection)
    if self.meleeComboPosition == MELEE_COMBO_LENGTH then
      step = step * 1.5
    end
    self.meleeHitboxAngle = self.meleeHitboxAngle + step

    if (self.meleeSwipeDirection > 0 and self.meleeHitboxAngle >= self.meleeEndAngle) or
       (self.meleeSwipeDirection < 0 and self.meleeHitboxAngle <= self.meleeEndAngle) then
      self.isMeleeing = false
      -- the last attack in the combo has a small amount of end lag
      if self.meleeComboPosition == MELEE_COMBO_LENGTH then
        self.meleeCooldown = MELEE_SPIN_END_LAG
      end

      self.meleeComboResetTime = 0.25
    end

    -- add a new point to the list
    local pos = Vector2.fromPolar(self.meleeHitboxAngle + self.meleeAngleOffset, 50)
    self.meleeTrailPoints[#self.meleeTrailPoints+1] = {
      position = pos,
      time = 0.2
    }
  elseif self.meleeComboResetTime > 0 then
    self.meleeComboResetTime = self.meleeComboResetTime - dt
    if self.meleeComboResetTime <= 0 then
      self.meleeSwipeDirection = 1
      self.meleeComboPosition = 0
    end
  end

  -- update timers and remove points
  if #self.meleeTrailPoints > 0 then
    local filteredPoints = {}
    for _, pt in pairs(self.meleeTrailPoints) do
      pt.time = pt.time - dt
      if pt.time > 0 then
        filteredPoints[#filteredPoints+1] = pt
      end
    end
    self.meleeTrailPoints = filteredPoints
  end
end

function Player:beginDash(dashVector)
  self.remainingDashes = self.remainingDashes - 1

  self.velocity = dashVector:setMag(self.DASH_SPEED)
  self.dashTimer = self.DASH_DURATION

  self.isMeleeing = false
  self.meleeCooldown = 0
  self.meleeComboPosition = 0
  self.meleeSwipeDirection = 1
end

return Player