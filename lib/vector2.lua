-- A 2D vector class for doing 2D vector things.

local utils = require "lib.utils"

---@class Vector2
---@field x number
---@field y number
---@field new fun(x?: number, y?:number): Vector2
---@field coords fun(self): number, number
---@field copy fun(self): Vector2
---@field normalize fun(self): self
---@field angle fun(self, degrees?: boolean): number
---@field setAngle fun(self, theta: number, degrees?: boolean): self
---@field rotate fun(self, theta: number, degrees?: boolean): number
---@field mag fun(self): number
---@field magSq fun(self): number
---@field setMag fun(self, newMag: number): self
---@field addMag fun(self, value: number): number
---@field dot fun(self, vec: Vector2): number
---@field angleTo fun(self, vec: Vector2, degrees?: boolean): number
---@field limit fun(self, max: number): self
---@field lerp fun(v1: Vector2, v2: Vector2, t: number): Vector2
---@field damp fun(v1: Vector2, v2: Vector2, t: number, dt: number): Vector2
---@operator call: Vector2
---@operator add(Vector2): Vector2
---@operator sub(Vector2): Vector2
---@operator mul(number): Vector2
---@operator div(number): Vector2
---@operator unm: Vector2
local Vector2 = setmetatable({}, {
  __call = function(v, ...) return v.new(...) end})
local Vector2Metatable = {
  __index = Vector2
}

---Constructs a new Vector2.
---@param x? number [0]
---@param y? number [0]
---@return Vector2
---@nodiscard
function Vector2.new(x, y)
  local v = {x = x or 0, y = y or 0}
  setmetatable(v, Vector2Metatable) -- gives v all the Vector methods
  return v
end

---Returns a Vector2 constructed from polar coordinates.
---@param theta number The angle of the vector.
---@param r number The length of the vector.
---@param degrees? boolean [false] Whether to use degrees or radians for theta.
---@return Vector2
---@nodiscard
function Vector2.fromPolar(theta, r, degrees)
  -- if degrees isn't included it will be nil, so there's no need to set it to false explicitly
  if degrees then
    theta = math.rad(theta)
  end

  return Vector2.new(
    math.cos(theta) * r,
    math.sin(theta) * r
  )
end

---Returns a copy of the vector.
---@return Vector2
---@nodiscard
function Vector2:copy()
  return Vector2.new(self.x, self.y)
end

---Returns the vector's coordinates as an unpacked pair of numbers.
---@return number, number
---@nodiscard
function Vector2:coords()
  return self.x, self.y
end

---Sets the vector's length to 1. Has no effect if the vector has length 0.
function Vector2:normalize()
  if self.x ~= 0 or self.y ~= 0 then
    local m = self:mag()
    self.x = self.x / m
    self.y = self.y / m
  end

  return self
end

---Returns the angle of the vector, or 0 if the vector has length 0.
---@param degrees? boolean [false] Whether to return the angle in degrees or radians.
---@return number
---@nodiscard
function Vector2:angle(degrees)
  if self.x == 0 and self.y == 0 then
    return 0
  end

  if degrees then
    return math.deg(utils.atan2(self.y, self.x))
  end
  return utils.atan2(self.y, self.x)
end

---Sets the angle of the vector. Has no effect on vectors with length 0.
---@param theta number The new angle.
---@param degrees? boolean [false] Whether to use degrees or radians.
function Vector2:setAngle(theta, degrees)
  if self.x ~= 0 or self.y ~= 0 then
    if degrees then
      theta = math.rad(theta)
    end
  
    local m = self:mag()
    self.x = math.cos(theta) * m
    self.y = math.sin(theta) * m
  end

  return self
end

---Rotates the vector by a certain angle. Has no effect on vectors with length 0.
---@param theta number The angle to rotate by.
---@param degrees? boolean [false] Whether to use degrees or radians.
---@return number newAngle The new angle of the vector.
function Vector2:rotate(theta, degrees)
  if self.x == 0 and self.y == 0 then
    return 0
  end

  if degrees then
    theta = math.rad(theta)
  end

  local newAngle = self:angle() + theta
  self:setAngle(newAngle)

  if degrees then
    return math.deg(newAngle)
  end
  return newAngle
end

---Returns the length of the vector.
---@return number
---@nodiscard
function Vector2:mag()
  return math.sqrt(self.x^2 + self.y^2)
end

---Returns the length of the vector squared. Avoids an expensive square root operation, so use this
---in place of `mag()` if you can get away with it.
---@return number
---@nodiscard
function Vector2:magSq()
  return self.x^2 + self.y^2
end

---Sets the length of the vector. Has no effect on vectors of length 0
---@param newMag number
function Vector2:setMag(newMag)
  local m = self:mag()
  if m > 0 then
    self.x = self.x * newMag / m
    self.y = self.y * newMag / m
  end

  return self
end

---Adds a value to the length of the vector. Has no effect on vectors of length 0.
---@param value number
---@return number newMag The new length of the vector.
function Vector2:addMag(value)
  local m = self:mag()
  local newMag = m + value
  if m > 0 then
    self.x = self.x * newMag / m
    self.y = self.y * newMag / m
  end
  return newMag
end

---Returns the dot product of this vector and another vector.
---@param vec Vector2
---@return number
---@nodiscard
function Vector2:dot(vec)
  return self.x * vec.x + self.y * vec.y
end

---Returns the cross product (kind of) of this vector and another vector.
function Vector2:cross(vec)
  return self.x * vec.y - self.y * vec.x
end

---Returns the angle between this vector and another vector.
---@param vec Vector2
---@param degrees? boolean [false] Whether to return the angle in degrees or radians.
---@return number
---@nodiscard
function Vector2:angleTo(vec, degrees)
  local m1 = self:mag()
  local m2 = vec:mag()
  local d = self:dot(vec)

  if degrees then
    return math.deg(utils.constrainAngle(math.acos(d / (m1 * m2))))
  end
  return utils.constrainAngle(math.acos(d / (m1 * m2)))
end

---Limits the vector to a maximum length.
---@param max number
function Vector2:limit(max)
  if self:magSq() > max^2 then
    self:setMag(max)
  end

  return self
end

---Static method that interpolates between two vectors and returns a new vector.
---@param v1 Vector2
---@param v2 Vector2
---@param t number The amount to interpolate by. 0 returns v1, and 1 returns v2.
---@return Vector2
---@nodiscard
function Vector2.lerp(v1, v2, t)
  return Vector2.new(
    utils.lerp(v1.x, v2.x, t),
    utils.lerp(v1.y, v2.y, t)
  )
end

---Framerate-independent version of `lerp()` using delta time
---@param v1 Vector2
---@param v2 Vector2
---@param t number The amount to interpolate by. 0 returns v1, and 1 returns v2.
---@param dt number The current delta time; makes the result framerate-independent.
---@return Vector2
---@nodiscard
function Vector2.damp(v1, v2, t, dt)
  return Vector2.lerp(v1, v2, 1 - math.exp(-t * dt))
end

function Vector2Metatable.__add(a, b)
  return Vector2.new(a.x + b.x, a.y + b.y)
end

function Vector2Metatable.__sub(a, b)
  return Vector2.new(a.x - b.x, a.y - b.y)
end

function Vector2Metatable.__mul(vec, scalar)
  return Vector2.new(vec.x * scalar, vec.y * scalar)
end

function Vector2Metatable.__div(vec, scalar)
  return Vector2.new(vec.x / scalar, vec.y / scalar)
end

function Vector2Metatable.__unm(v)
  return Vector2.new(-v.x, -v.y)
end

function Vector2Metatable.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

function Vector2Metatable.__ne(a, b)
  return not a == b
end

function Vector2Metatable.__lt(a, b)
  return a.magSq() < b.magSq()
end

function Vector2Metatable.__le(a, b)
  return a.magSq() <= b.magSq()
end

function Vector2Metatable.__tostring(v)
  return string.format("(%.2f, %.2f)", v.x, v.y)
end

return Vector2