-- Filename starts with an underscore so it's always at the top of the list in my editor.

return {
  graphics = {
    width = 1280,
    height = 720,
    fullscreen = false, -- overrides width and height
    vsync = "adaptive", -- true, false, or "adaptive"
    msaaSamples = 8,    -- number of samples for antialiasing
  },

  keybinds = {
    {
      name = "test rumble",
      keys = {"a"},
      gamepadButtons = {"a"},
      mode = "press"
    },
  },

  -- size of the input buffer in seconds
  inputBufferSize = 0.5,
  -- gamepad analog values lower than this are clamped to 0
  gamepadLowDeadzone = 0.1,
  -- gamepad analog values higher than this are clamped to 1
  gamepadHighDeadzone = 0.95
}
