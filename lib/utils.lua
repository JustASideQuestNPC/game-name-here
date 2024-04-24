-- Various utility functions

---Returns whether a predicate function returns true for every item in an array.
---@param arr table
---@param predicate function
---@return boolean
---@nodiscard
local function arrayEvery(arr, predicate)
  for _, v in ipairs(arr) do
    if not predicate(v) then
      return false
    end
  end
  return true
end

---Returns whether a predicate function returns true for at least one item in an array.
---@param arr table
---@param predicate function
---@return boolean
---@nodiscard
local function arrayAny(arr, predicate)
  for _, v in ipairs(arr) do
    if predicate(v) then
      return true
    end
  end
  return false
end

---Returns the first index of a value in an array, or 0 if the value is not in the array.
---@param arr any
---@param value any
---@return integer
local function arrayFind(arr, value)
  for i, v in ipairs(arr) do
    if v == value then
      return i
    end
  end

  return 0
end

---Returns a copy of an array containing only items that a predicate function returns true for.
---@param arr table
---@param predicate function
---@return table
local function arrayFilter(arr, predicate)
  local filtered = {}
  for _, v in ipairs(arr) do
    if predicate(v) then
      filtered[#filtered+1] = v
    end
  end
  return filtered
end

---Interpolates between two numbers.
---@param a number
---@param b number
---@param t number The amount to interpolate by. 0 returns a, and 1 returns b.
---@return number
---@nodiscard
local function lerp(a, b, t)
  return t < 0.5 and a + (b - a) * t or b + (a - b) * (1 - t)
end

---Framerate-independent version of `lerp()` using delta time
---@param a number
---@param b number
---@param t number The amount to interpolate by. 0 returns a, and 1 returns b.
---@param dt number The current delta time; makes the result framerate-independent.
---@return number
---@nodiscard
local function damp(a, b, t, dt)
  return lerp(a, b, math.exp(-t * dt))
end

---Maps a value between two ranges.
---@param value number
---@param inputStart number
---@param inputEnd number
---@param outputStart number
---@param outputEnd number
---@return number
---@nodiscard
local function map(value, inputStart, inputEnd, outputStart, outputEnd)
  return outputStart + ((outputEnd - outputStart) / (inputEnd - inputStart)) * (value - inputStart)
end

return {
  arrayEvery = arrayEvery,
  arrayAny = arrayAny,
  arrayFind = arrayFind,
  arrayFilter = arrayFilter,
  lerp = lerp,
  damp = damp,
  map = map,
}