-----------------------------------------------------
-- nvim-surround - Surround text with quotes, brackets, and more
--
-- This plugin provides mappings to easily surround items with pairs
-- like (), [], {}, etc. It's a replacement for mini.surround, which
-- had issues with key binding conflicts.
--
-- Default mappings:
-- - ys{motion}{char} - Add surround around motion
-- - ds{char} - Delete surround character
-- - cs{old}{new} - Change surround from old to new
--
-- Examples:
-- - ysiw" - Surround word with quotes
-- - ds{ - Delete surrounding {} braces
-- - cs"' - Change surrounding quotes from double to single
--
-- Visual Mode:
-- - S{char} - Surround selected text
-----------------------------------------------------

return {
  "kylechui/nvim-surround", 
  version = "*",  -- Use the latest stable release 
  event = "BufReadPost",  -- Load when reading files (ready for text manipulation)
  opts = {},
}