-- Game settings.
-- PS: The only reason the filename starts with an underscore is so that it's always at the top
-- when I sort the folder alphabetically.

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
      name = "continuous action",
      keys = {"space"}
    },
    {
      name = "press action",
      keys = {"space"},
      mode = "press"
    },
    {
      name = "release action",
      keys = {"space"},
      mode = "release"
    },
    {
      name = "multiple keys",
      keys = {"lshift", "left mouse"}
    },
    {
      name = "chord action",
      keys = {"lshift", "left mouse"},
      chord = true
    }
  }
}
