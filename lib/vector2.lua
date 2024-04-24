-- A 2D vector class for doing 2D vector things.
local utils = require "lib.utils"

---@class Vector2
---@field x number
---@field y number
---@field copy function
---@field normalize function
---@field angle function
---@field setAngle function
---@field rotate function
---@field mag function
---@field magSq function
---@field setMag function
---@field addMag function
---@field dot function
---@field angleTo function
---@field lerp function
---@field damp function
---@operator add(Vector2) : Vector2
---@operator sub(Vector2) : Vector2
---@operator mul(number) : Vector2
---@operator div(number) : Vector2
---@operator unm : Vector2

local Vector2 = {}

---Constructs a new Vector2.
---@param x? number [0]
---@param y? number [0]
---@return Vector2
---@nodiscard
function Vector2.new(x, y)
  local v = {x = x or 0, y = y or 0}
  setmetatable(v, {
    __index = Vector2,
    __add = Vector2.__add,
    __sub = Vector2.__sub,
    __mul = Vector2.__mul,
    __div = Vector2.__div,
    __unm = Vector2.__unm,
    __eq = Vector2.__eq,
    __ne = Vector2.__ne,
    __lt = Vector2.__lt,
    __le = Vector2.__le,
    __tostring = Vector2.__tostring
  }) -- gives v all the Vector methods
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

---Sets the vector's length to 1. Has no effect if the vector has length 0.
function Vector2:normalize()
  if self.x == 0 and self.y == 0 then
    return
  end

  local m = self:mag()
  self.x = self.x / m
  self.y = self.y / m
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
    return math.deg(math.atan(self.y, self.x))
  end
  return math.atan(self.y, self.x)
end

---Sets the angle of the vector. Has no effect on vectors with length 0.
---@param theta number The new angle.
---@param degrees? boolean [false] Whether to use degrees or radians.
function Vector2:setAngle(theta, degrees)
  if self.x == 0 and self.y == 0 then
    return
  end

  if degrees then
    theta = math.rad(theta)
  end

  local m = self:mag()
  self.x = math.cos(theta) * m
  self.y = math.sin(theta) * m
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

---Sets the length of the vector.
---@param newMag number
function Vector2:setMag(newMag)
  local m = self:mag()
  self.x = self.x * newMag / m
  self.y = self.y * newMag / m
end

---Adds a value to the length of the vector.
---@param value number
---@return number newMag The new length of the vector.
function Vector2:addMag(value)
  local m = self:mag()
  local newMag = m + value

  self.x = self.x * newMag / m
  self.y = self.y * newMag / m

  return newMag
end

---Returns the dot product of this vector and another vector.
---@param vec Vector2
---@return number
---@nodiscard
function Vector2:dot(vec)
  return self.x * vec.x + self.y * vec.y
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
    return math.deg(math.acos(d / (m1 * m2)))
  end
  return math.acos(d / (m1 * m2))
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
  return Vector2.lerp(v1, v2, math.exp(-t * dt))
end

function Vector2.__add(a, b)
  return Vector2.new(a.x + b.x, a.y + b.y)
end

function Vector2.__sub(a, b)
  return Vector2.new(a.x - b.x, a.y - b.y)
end

function Vector2.__mul(vec, scalar)
  return Vector2.new(vec.x * scalar, vec.y * scalar)
end

function Vector2.__div(vec, scalar)
  return Vector2.new(vec.x / scalar, vec.y / scalar)
end

function Vector2.__unm(v)
  return Vector2.new(-v.x, -v.y)
end

function Vector2.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

function Vector2.__ne(a, b)
  return not a == b
end

function Vector2.__lt(a, b)
  return a.magSq() < b.magSq()
end

function Vector2.__le(a, b)
  return a.magSq() <= b.magSq()
end

function Vector2.__tostring(v)
  return string.format("(%.2f, %.2f)", v.x, v.y)
end

return Vector2