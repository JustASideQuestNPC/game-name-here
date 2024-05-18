local utils = require "lib.utils"
local input = require "lib.input"

local function drawTextCentered(text, font, x, y)
  local width = font:getWidth(text)
  local height = font:getAscent() + font:getDescent()

  love.graphics.print(text, x - width / 2, y - height / 2)
end

---@class ListMenu: Class
---@field x number
---@field y number
---@field scale number
---@field title string
---@field titleFont table
---@field titleColor table
---@field options table[]
---@field optionsFont table
---@field optionsColor table
---@field optionsHoverColor table
---@field optionLineHeight number
---@field optionListHeight number
---@field optionListOffset number
---@field titleOffset number
---@field hoveredOption table
---@field gamepadSelectedOption number
---@field update fun(self)
---@field draw fun(self)
local ListMenu = utils.class(
  function (instance, args)
    instance.x = args.pos[1]
    instance.y = args.pos[2]
    instance.scale = args.scale

    instance.title = args.title
    instance.titleFont = args.titleFont
    instance.titleColor = args.titleColor
    instance.options = args.options
    instance.optionsFont = args.optionsFont
    instance.optionsColor = args.optionsColor
    instance.optionsHoverColor = args.optionsHoverColor

    instance.optionLineHeight = (instance.optionsFont:getAscent() +
        instance.optionsFont:getDescent()) * args.optionsLineSpacing
    instance.optionListHeight = instance.optionLineHeight * #instance.options

    if instance.title ~= "" then
      local titleHeight = (instance.titleFont:getAscent() + instance.titleFont:getDescent())
      local totalHeight = instance.optionListHeight + titleHeight + args.titleOffset
      instance.titleOffset = -totalHeight / 2
      instance.optionListOffset = totalHeight / 2 - instance.optionListHeight / 2
    else
      instance.titleOffset = 0
      instance.optionListOffset = 0
    end

    -- generate option data
    for i, option in ipairs(instance.options) do
      local yPos = -instance.optionListHeight / 2 + (i - 1) * instance.optionLineHeight
      local w = instance.optionsFont:getWidth(option.text) * 1.1
      option.bbox = {
        x = -w / 2,
        y = yPos + instance.optionListOffset - instance.optionLineHeight / 4,
        w = w,
        h = instance.optionLineHeight
      }

      option.hovered = false
    end

    instance.hoveredOption = nil
    instance.gamepadSelectedOption = 1
  end
)

function ListMenu:update()
  if input.currentInputType() == "keyboard" then
    self.hoveredOption = nil
    for i, option in ipairs(self.options) do
      option.hovered = input.mouseOver(
        self.x + option.bbox.x * self.scale,
        self.y + option.bbox.y * self.scale,
        (option.bbox.w) * self.scale,
        (option.bbox.h) * self.scale
      )

      if option.hovered then
        self.hoveredOption = option
        self.gamepadSelectedOption = i
      end
    end
  else
    local menuDir = input.getDpadVector("menu up", "menu down", "menu left", "menu right")
    if menuDir.y < 0 then
      self.gamepadSelectedOption = self.gamepadSelectedOption - 1
      if self.gamepadSelectedOption == 0 then
        self.gamepadSelectedOption = #self.options
      end
    elseif menuDir.y > 0 then
      self.gamepadSelectedOption = self.gamepadSelectedOption + 1
      if self.gamepadSelectedOption > #self.options then
        self.gamepadSelectedOption = 1
      end
    end

    self.hoveredOption = self.options[self.gamepadSelectedOption]
  end
end

function ListMenu:draw()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.scale(self.scale)

  if self.title ~= "" then
    love.graphics.push()
    love.graphics.translate(0, self.titleOffset)

    love.graphics.setColor(self.titleColor)
    love.graphics.setFont(self.titleFont)
    drawTextCentered(self.title, self.titleFont, 0, 0)
    love.graphics.pop()
  end

  love.graphics.translate(0, self.optionListOffset)
  love.graphics.setFont(self.optionsFont)

  for i, option in ipairs(self.options) do
    local yPos = -self.optionListHeight / 2 + (i - 1) * self.optionLineHeight
    if (input.currentInputType() == "keyboard" and option.hovered) or
       (input.currentInputType() == "gamepad"  and i == self.gamepadSelectedOption) then
      love.graphics.setColor(self.optionsHoverColor)
    else
      love.graphics.setColor(self.optionsColor)
    end
    drawTextCentered(option.text, self.optionsFont, 0, yPos)
  end

  love.graphics.pop()

  if DEBUG_CONFIG.SHOW_HITBOXES then
    love.graphics.setColor(love.math.colorFromBytes(94, 253, 247))
    for _, option in ipairs(self.options) do
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line",
        self.x + option.bbox.x * self.scale,
        self.y + option.bbox.y * self.scale,
        (option.bbox.w) * self.scale,
        (option.bbox.h) * self.scale
      )
    end
  end
end

return ListMenu