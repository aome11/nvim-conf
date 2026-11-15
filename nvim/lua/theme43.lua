-- Colorscheme that follows the 43PR desktop theme.
-- Reads ~/.cache/43pr/palette.json (rewritten by theme.py on every wallpaper / preset / mode change)
-- and re-applies itself live in every open Neovim when that file changes.
-- Set `vim.g.theme43_transparent = true` (before the colorscheme loads) to keep the terminal background.
local M = {}

local cache = (vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache")) .. "/43pr"
local file = cache .. "/palette.json"

-- Used for any key missing from the palette (the 43PR default preset).
local fallback = {
  bg = "#000000", fg = "#ffffff", accent = "#ffffff", highlight = "#7aa2f7",
  danger = "#ff003c", ok = "#00ff9c", cursor = "#cccccc", cursor_text = "#111111",
  term0 = "#000000", term1 = "#cc0403", term2 = "#e2e2e2", term3 = "#cecb00",
  term4 = "#0d73cc", term5 = "#cb1ed1", term6 = "#0dcdcd", term7 = "#dddddd",
  term8 = "#767676", term9 = "#f2201f", term10 = "#23fd00", term11 = "#fffd00",
  term12 = "#1a8fff", term13 = "#fd28ff", term14 = "#14ffff", term15 = "#ffffff",
}

local function read_palette()
  local p = vim.deepcopy(fallback)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then return p end
  local ok2, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok2 or type(data) ~= "table" then return p end
  for k in pairs(fallback) do
    if type(data[k]) == "string" and data[k]:match("^#%x%x%x%x%x%x$") then p[k] = data[k] end
  end
  return p
end

-- ---------- color helpers ----------
local function rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

-- mix(a, b, t): t = 0 gives a, t = 1 gives b
local function mix(a, b, t)
  local ar, ag, ab = rgb(a)
  local br, bg, bb = rgb(b)
  return string.format("#%02x%02x%02x",
    math.floor(ar + (br - ar) * t + 0.5),
    math.floor(ag + (bg - ag) * t + 0.5),
    math.floor(ab + (bb - ab) * t + 0.5))
end

local function luminance(hex)
  local function lin(v)
    v = v / 255
    return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  local r, g, b = rgb(hex)
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
end

local function contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then la, lb = lb, la end
  return (la + 0.05) / (lb + 0.05)
end

-- push a color toward the foreground until it is readable on the background
local function readable(c, bg, fg, min)
  for _ = 1, 8 do
    if contrast(c, bg) >= (min or 3.5) then break end
    c = mix(c, fg, 0.18)
  end
  return c
end

-- ---------- highlight groups ----------
local function groups(p)
  local bg, fg = p.bg, p.fg
  local dim = mix(bg, fg, 0.75)
  local muted = readable(mix(bg, fg, 0.55), bg, fg, 3.3) -- comments: dim, but never hard to read
  local faint = mix(bg, fg, 0.30)
  local line = mix(bg, fg, 0.06)
  local float = mix(bg, fg, 0.04)
  local menu = mix(bg, fg, 0.09)
  local bar = mix(bg, fg, 0.08)
  local sel = mix(bg, p.accent, 0.30)

  local function c(k) return readable(p[k], bg, fg) end
  local red, green, yellow, blue, magenta, cyan = c("term1"), c("term2"), c("term3"), c("term4"), c("term5"), c("term6")
  local accent = readable(p.accent, bg, fg)
  local danger = readable(p.danger, bg, fg)
  local ok = readable(p.ok, bg, fg)
  local transparent = vim.g.theme43_transparent

  local function diff(color) return { bg = mix(bg, color, 0.22) } end
  local function under(color) return { undercurl = true, sp = color } end

  return {
    -- editor
    Normal = { fg = fg, bg = transparent and "NONE" or bg },
    NormalNC = { link = "Normal" },
    NormalFloat = { fg = fg, bg = transparent and "NONE" or float },
    FloatBorder = { fg = faint, bg = transparent and "NONE" or float },
    FloatTitle = { fg = accent, bold = true },
    Cursor = { fg = p.cursor_text, bg = p.cursor },
    lCursor = { link = "Cursor" }, CursorIM = { link = "Cursor" }, TermCursor = { link = "Cursor" },
    CursorLine = { bg = line }, CursorColumn = { bg = line }, ColorColumn = { bg = line },
    LineNr = { fg = faint }, CursorLineNr = { fg = accent, bold = true },
    SignColumn = { fg = faint }, FoldColumn = { fg = faint }, Folded = { fg = muted, bg = line },
    Visual = { bg = sel }, VisualNOS = { bg = sel },
    Search = { fg = bg, bg = yellow }, CurSearch = { fg = bg, bg = accent }, IncSearch = { fg = bg, bg = accent },
    Substitute = { fg = bg, bg = red },
    MatchParen = { fg = accent, bold = true, underline = true },
    Pmenu = { fg = fg, bg = menu }, PmenuSel = { bg = sel }, PmenuSbar = { bg = menu }, PmenuThumb = { bg = faint },
    PmenuKind = { fg = cyan }, PmenuExtra = { fg = muted },
    StatusLine = { fg = fg, bg = bar }, StatusLineNC = { fg = muted, bg = bar },
    WinBar = { fg = fg }, WinBarNC = { fg = muted },
    TabLine = { fg = muted, bg = bar }, TabLineFill = { bg = bar }, TabLineSel = { fg = bg, bg = accent },
    WinSeparator = { fg = faint }, VertSplit = { link = "WinSeparator" },
    EndOfBuffer = { fg = bg }, NonText = { fg = faint }, Whitespace = { fg = faint }, SpecialKey = { fg = faint },
    Directory = { fg = blue }, Title = { fg = accent, bold = true },
    Question = { fg = green }, MoreMsg = { fg = green }, ModeMsg = { fg = fg, bold = true },
    WarningMsg = { fg = yellow }, ErrorMsg = { fg = danger },
    Conceal = { fg = muted },
    SpellBad = under(red), SpellCap = under(yellow), SpellLocal = under(cyan), SpellRare = under(magenta),

    -- syntax
    Comment = { fg = muted, italic = true },
    Constant = { fg = yellow }, String = { fg = green }, Character = { link = "String" },
    Number = { fg = yellow }, Boolean = { fg = yellow }, Float = { link = "Number" },
    Identifier = { fg = fg }, Function = { fg = blue },
    Statement = { fg = magenta }, Conditional = { link = "Statement" }, Repeat = { link = "Statement" },
    Label = { link = "Statement" }, Keyword = { link = "Statement" }, Exception = { link = "Statement" },
    Operator = { fg = dim },
    PreProc = { fg = cyan }, Include = { link = "PreProc" }, Define = { link = "PreProc" },
    Macro = { link = "PreProc" }, PreCondit = { link = "PreProc" },
    Type = { fg = cyan }, StorageClass = { link = "Type" }, Structure = { link = "Type" }, Typedef = { link = "Type" },
    Special = { fg = accent }, SpecialChar = { link = "Special" }, Tag = { link = "Special" },
    Delimiter = { fg = dim }, SpecialComment = { link = "Special" }, Debug = { link = "Special" },
    Underlined = { underline = true }, Ignore = { fg = faint },
    Error = { fg = danger }, Todo = { fg = bg, bg = yellow, bold = true },
    ["@variable"] = { fg = fg },
    ["@variable.builtin"] = { fg = red },
    ["@variable.parameter"] = { fg = fg, italic = true },
    ["@constructor"] = { fg = cyan },
    ["@property"] = { fg = dim },
    ["@markup.heading"] = { link = "Title" },
    ["@markup.link"] = { fg = blue, underline = true },

    -- diff / git
    DiffAdd = diff(green), DiffChange = diff(blue), DiffDelete = diff(red), DiffText = diff(yellow),
    Added = { fg = green }, Changed = { fg = blue }, Removed = { fg = red },

    -- diagnostics
    DiagnosticError = { fg = danger }, DiagnosticWarn = { fg = yellow }, DiagnosticInfo = { fg = blue },
    DiagnosticHint = { fg = cyan }, DiagnosticOk = { fg = ok },
    DiagnosticUnderlineError = under(danger), DiagnosticUnderlineWarn = under(yellow),
    DiagnosticUnderlineInfo = under(blue), DiagnosticUnderlineHint = under(cyan),
    DiagnosticVirtualTextError = { fg = danger }, DiagnosticVirtualTextWarn = { fg = yellow },
    DiagnosticVirtualTextInfo = { fg = blue }, DiagnosticVirtualTextHint = { fg = cyan },
  }
end

function M.load()
  local p = read_palette()
  local want = luminance(p.bg) > 0.4 and "light" or "dark"

  vim.g.colors_name = nil -- otherwise changing 'background' would re-run the colorscheme
  vim.o.termguicolors = true
  if vim.o.background ~= want then vim.o.background = want end
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end

  for name, spec in pairs(groups(p)) do vim.api.nvim_set_hl(0, name, spec) end
  for i = 0, 15 do vim.g["terminal_color_" .. i] = p["term" .. i] end
  vim.g.colors_name = "theme43"
end

-- Re-apply whenever theme.py rewrites the palette. We watch the directory, not the file,
-- because theme.py replaces palette.json atomically (a watch on the file itself would be lost).
local watcher, timer
function M.watch()
  if watcher then return end
  watcher = vim.uv.new_fs_event()
  timer = vim.uv.new_timer()
  local started = watcher and watcher:start(cache, {}, function(err, name)
    if err or name ~= "palette.json" then return end
    timer:stop()
    timer:start(150, 0, vim.schedule_wrap(function()
      if vim.g.colors_name == "theme43" then vim.cmd.colorscheme("theme43") end
    end))
  end)
  if not started then watcher = nil end
end

return M
