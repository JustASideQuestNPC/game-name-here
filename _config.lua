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
  }
}
