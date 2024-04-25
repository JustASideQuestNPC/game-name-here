-- Filename starts with an underscore so it's always at the top of the list in my editor.

return {
  graphics = {
    width = 1280,
    height = 720,
    fullscreen = false, -- overrides width and height
    vsync = "adaptive", -- true, false, or "adaptive"
    msaaSamples = 8,    -- number of samples for antialiasing
  },

  input = {
    keybinds = {
      {
        name = "test rumble",
        keys = {"a"},
        gamepadButtons = {"a"},
        mode = "press"
      },
    },

    bufferSize = 0.5,   -- size of the input buffer in seconds
    lowDeadzone = 0.1,  -- gamepad analog values lower than this are clamped to 0
    highDeadzone = 0.95 -- gamepad analog values higher than this are clamped to 1
  },

  engine = {
    cameraTightness = 1.0 -- determines how quickly the camera moves
  },

  gameplay = {
    roomWidth = 1500, -- width of the playable area in pixels
    roomHeight = 900  -- height of the playable area in pixels
  }
}
