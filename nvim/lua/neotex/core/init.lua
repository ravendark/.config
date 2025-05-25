require("neotex.core.autocmds")
require("neotex.core.functions")
require("neotex.core.keymaps")
require("neotex.core.options")
local function getWords()
  return tostring(fim.fn.wordcount().words)
end
-- Load Avante support module
require("neotex.plugins.ai.avante-support")
