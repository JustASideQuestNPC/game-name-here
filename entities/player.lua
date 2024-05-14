-- Player character.

local HC           = require "hardonCollider"
local playerConfig = require "_gameConfig".entities.player
local utils        = require "lib.utils"
local input        = require "lib.input"
local Vector2      = require "lib.vector2"
local Sprite       = require "lib.sprite"
local temp         = require "lib.gameEntity"
local GameEntity, EntityTag = temp.GameEntity, temp.EntityTag

local MELEE_COMBO_LENGTH = playerConfig.meleeComboLength
local MELEE_JAB_ANGLE_SIZE = math.rad(playerConfig.meleeJabAngleSize)
local MELEE_SPIN_END_LAG = playerConfig.meleeSpinEndLag

local INITIAL_BULLET_SPREAD = math.rad(playerConfig.initialBulletSpread) / 2
local UNAIM_SPEED = math.rad(playerConfig.unAimSpeed)

---@class PlayerBullet: GameEntity
---@field position Vector2
---@field velocity Vector2
---@field damage number
---@field maxDistance number
---@field distanceTraveled number
---@field charged boolean
local PlayerBullet = utils.class(
  GameEntity, function (instance, position, velocity, damage, maxDistance, charged)
    instance.tags = {EntityTag.PLAYER_BULLET}
    instance.displayLayer = 0

    instance.position = position:copy()
    instance.velocity = velocity:copy()
    instance.damage = damage
    instance.maxDistance = maxDistance
    instance.distanceTraveled = 0
    instance.charged = charged
  end
)

function PlayerBullet:draw()
  if self.charged then
    love.graphics.setColor(love.math.colorFromBytes(133, 218, 235))
    love.graphics.circle("fill", self.position.x, self.position.y, 15)
  else
    love.graphics.setColor(love.math.colorFromBytes(95, 161, 231))
    love.graphics.circle("fill", self.position.x, self.position.y, 10)
  end
end

function PlayerBullet:update(dt)
  local step = self.velocity * dt
  self.position = self.position + step
  self.distanceTraveled = self.distanceTraveled + step:mag()
  if self.distanceTraveled > self.maxDistance then
    self.markForDelete = true
  end
end

---@class Player: GameEntity
---@field RUN_SPEED number pixels per second
---@field DASH_SPEED number pixels per second
---@field DASH_DURATION number seconds
---@field MAX_CONSECUTIVE_DASHES integer how many dashes can be performed in quick succession
---@field DASH_REFRESH_DURATION number how many seconds before all dashes are replenished
---@field AIM_SPEED number radians per second
---@field AIM_SPEED_WHILE_FIRING number radians per second
---@field BULLET_VELOCITY number pixels per second
---@field BULLET_RANGE number pixels
---@field SHOT_DELAY number seconds between shots
---@field SHOT_CHARGE_DELAY number seconds
---@field sprite Sprite
---@field hitbox table
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
---@field currentBulletSpread number
---@field isAiming boolean
---@field shotTimer number
---@field shotChargeTimer number
---@field beginDash fun(self, dashVector: Vector2)
local Player = utils.class(
  GameEntity, function (instance, x, y)
    instance.tags = {EntityTag.PLAYER}
    instance.displayLayer = 1

    instance.RUN_SPEED = playerConfig.runSpeed
    instance.DASH_SPEED = playerConfig.dashSpeed
    instance.DASH_DURATION = playerConfig.dashDuration
    instance.MAX_CONSECUTIVE_DASHES = playerConfig.maxConsecutiveDashes
    instance.DASH_REFRESH_DURATION = playerConfig.dashRefreshDuration
    instance.AIM_SPEED = math.rad(playerConfig.aimSpeed)
    instance.AIM_SPEED_WHILE_FIRING = math.rad(playerConfig.aimSpeedWhileFiring)
    instance.BULLET_VELOCITY = playerConfig.bulletVelocity
    instance.BULLET_RANGE = playerConfig.bulletRange
    instance.SHOT_DELAY = 1 / (playerConfig.fireRate / 60)
    instance.SHOT_CHARGE_DELAY = playerConfig.shotChargeTime

    instance.sprite = Sprite("player")
    instance.hitbox = HC.polygon(
        0, -25,
       20,  -5,
       20,  18,
       13,  25,
      -13,  25,
      -20,  18,
      -20,  -5
    )

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

    instance.currentBulletSpread = INITIAL_BULLET_SPREAD
    instance.isAiming = false
    instance.shotTimer = 0
    instance.shotChargeTimer = 0
  end
)

function Player:draw()
  love.graphics.push()
  love.graphics.translate(self.position:coords())
  love.graphics.rotate(self.angle + math.pi / 2)

  -- draw aim direction
  if self.currentBulletSpread < INITIAL_BULLET_SPREAD then
    if self.shotChargeTimer <= 0 then
      love.graphics.setColor(love.math.colorFromBytes(133, 218, 235))
      utils.dottedLine(0, 0, 0, -self.BULLET_RANGE, 5, 20)
    else
      love.graphics.setColor(love.math.colorFromBytes(95, 161, 231))
      love.graphics.push()

      love.graphics.rotate(-self.currentBulletSpread)
      utils.dottedLine(0, 0, 0, -self.BULLET_RANGE, 5, 20)

      love.graphics.rotate(self.currentBulletSpread * 2)
      utils.dottedLine(0, 0, 0, -self.BULLET_RANGE, 5, 20)

      love.graphics.pop()
    end
  end

  self.sprite:draw(0, -4)

  -- draw melee positions
  love.graphics.rotate(-(self.angle + math.pi / 2))
  for _, pt in pairs(self.meleeTrailPoints) do
    love.graphics.setColor(love.math.colorFromBytes(133, 218, 235,
        utils.map(pt.time, 0, 0.2, 0, 255)))
    love.graphics.circle("fill", pt.position.x, pt.position.y, utils.map(pt.time, 0, 0.2, 0, 10))
  end

  love.graphics.pop()

  -- if DEBUG_CONFIG.SHOW_HITBOXES then
  --   love.graphics.setColor(love.math.colorFromBytes(94, 253, 247))
  --   love.graphics.setLineWidth(2)
  --   self.hitbox:draw("line")
  -- end
end

function Player:update(dt)
  -- move at the beginning of the update to prevent some issues with collisions
  self.position = self.position + self.velocity * dt
  self.hitbox:moveTo(self.position:coords())
  self.hitbox:setRotation(self.angle + math.pi / 2)

  -- check for collisions with walls
  local walls = Engine.getTagged(EntityTag.WALL)
  for _, wall in ipairs(walls) do
    local collides, dx, dy = self.hitbox:collidesWith(wall.hitbox)
    if collides then
      self.position = self.position + Vector2(dx, dy)
      self.hitbox:moveTo(self.position:coords())
    end
  end

  Engine.setCameraTarget(self.position)

  -- find aim direction
  self.isAiming = false
  local setAngleFromMovement = false
  if input.currentInputType() == "gamepad" then
    local lookVector = input.getStickVector("right")

    -- prevents a lot of weird and unfun control issues
    if lookVector:magSq() > 0.25 then
      self.isAiming = not self.isMeleeing
      local lookAngle = lookVector:angle()
      if math.abs(lookAngle - self.angle) > 0.02 then
        self.angle = lookVector:angle()
      end
    else
      setAngleFromMovement = true
    end
  else
    local mpos = Engine.screenPosToWorldPos(input.getMousePos())
    local delta = mpos - self.position
    self.angle = delta:angle()

    self.isAiming = (input.isActive("aim") or input.isActive("aim release")) and not self.isMeleeing
  end

  -- update ranged attack
  if self.shotTimer > 0 then
    self.shotTimer = self.shotTimer - dt
  end

  if self.isAiming then
    if (input.isActive("auto fire") or input.isActive("aim release")) and
        self.shotTimer <= 0 and self.dashTimer <= 0 then
      self.shotTimer = self.SHOT_DELAY

      local bulletAngle = self.angle + utils.randFloat(-self.currentBulletSpread,
        self.currentBulletSpread)
      local bulletVelocity
      if self.shotChargeTimer <= 0 then
        bulletVelocity = Vector2.fromPolar(bulletAngle, self.BULLET_VELOCITY * 1.5)
      else
        bulletVelocity = Vector2.fromPolar(bulletAngle, self.BULLET_VELOCITY)
      end

      Engine.addEntity(PlayerBullet(
        self.position, bulletVelocity + self.velocity, 0,
        self.BULLET_RANGE, self.shotChargeTimer < 0
      ))
      self.shotChargeTimer = self.SHOT_CHARGE_DELAY
    end

    if self.currentBulletSpread > 0 then
      self.shotChargeTimer = self.SHOT_CHARGE_DELAY
      if self.shotTimer > 0 then
        self.currentBulletSpread = math.max(
          self.currentBulletSpread - self.AIM_SPEED_WHILE_FIRING * dt, 0)
      else
        self.currentBulletSpread = math.max(self.currentBulletSpread - self.AIM_SPEED * dt, 0)
      end
    elseif self.shotChargeTimer > 0 and self.shotTimer <= 0 then
      self.shotChargeTimer = self.shotChargeTimer - dt
    end
  elseif self.currentBulletSpread < INITIAL_BULLET_SPREAD and self.shotTimer <= 0 then
    self.currentBulletSpread = math.min(
      self.currentBulletSpread + UNAIM_SPEED * dt, INITIAL_BULLET_SPREAD)
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
      moveDir = input.getStickVector("left")
    else
      moveDir = input.getDpadVector("move up", "move down", "move left", "move right")
    end

    -- update velocity
    if input.isActive("dash") and self.remainingDashes > 0 then
      if moveDir:magSq() > 0 then
        self:beginDash(moveDir)
      else
        self:beginDash(Vector2.fromPolar(self.angle, 1))
      end
    elseif moveDir:magSq() > 0 then
      self.velocity = moveDir * self.RUN_SPEED
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

  -- update melee attack
  if self.meleeCooldown > 0 then
    self.meleeCooldown = self.meleeCooldown - dt
    if self.meleeCooldown <= 0 then
      self.meleeSwipeDirection = 1
      self.meleeComboPosition = 0
    end
  end

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