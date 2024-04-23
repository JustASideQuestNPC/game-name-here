-- Various utility functions

---Returns whether a predicate function returns true for every item in an array.
---@param arr table
---@param predicate function
---@return boolean
---@nodiscard
local function arrayEvery(arr, predicate)
  for _, item in ipairs(arr) do
    if not predicate(item) then
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
  for _, item in ipairs(arr) do
    if predicate(item) then
      return true
    end
  end
  return false
end

---Interpolates between two numbers.
---@param start number
---@param stop number
---@param amount number The amount to interpolate by. 0 returns start, and 1 returns stop.
---@return number
---@nodiscard
local function lerp(start, stop, amount)
  return start * (1 - amount) + stop * amount
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
  lerp = lerp,
  map = map
}