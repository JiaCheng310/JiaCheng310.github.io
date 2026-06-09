local function parse_obsidian_image(text)
  local target, size = text:match("^%!%[%[([^%]|]+)%|([^%]]+)%]%]$")
  if target then
    return target, size
  end

  target = text:match("^%!%[%[([^%]]+)%]%]$")
  return target, nil
end

local function make_image(target, size)
  local attrs = {
    ["fig-align"] = "center"
  }

  if size then
    size = size:gsub("^%s+", ""):gsub("%s+$", "")
    local numeric = size:match("^(%d+)$")
    if numeric then
      attrs["width"] = numeric .. "px"
    else
      attrs["width"] = size
    end
  end

  local attr = pandoc.Attr("", { "obsidian-image" }, attrs)
  return pandoc.Image({}, target:gsub("^%s+", ""):gsub("%s+$", ""), "", attr)
end

local callout_titles = {
  note = "Note",
  abstract = "Abstract",
  summary = "Summary",
  tldr = "Summary",
  info = "Info",
  todo = "Todo",
  tip = "Tip",
  hint = "Hint",
  important = "Important",
  success = "Success",
  check = "Success",
  done = "Success",
  question = "Question",
  help = "Question",
  faq = "Question",
  warning = "Warning",
  caution = "Warning",
  attention = "Warning",
  failure = "Failure",
  fail = "Failure",
  missing = "Failure",
  danger = "Danger",
  error = "Danger",
  bug = "Bug",
  example = "Example",
  quote = "Quote",
  cite = "Quote"
}

local function parse_callout_marker(text)
  local kind = text:match("^%[!([%w_-]+)%][%+%-]?$")
  if not kind then
    return nil
  end

  return kind:lower()
end

local function trim_inline_edges(inlines)
  while #inlines > 0 and inlines[1].t == "Space" do
    table.remove(inlines, 1)
  end

  while #inlines > 0 and inlines[#inlines].t == "Space" do
    table.remove(inlines, #inlines)
  end

  return inlines
end

local function split_callout_head(inlines)
  local title = {}
  local content = {}
  local saw_break = false

  for i = 2, #inlines do
    local item = inlines[i]
    if not saw_break and (item.t == "SoftBreak" or item.t == "LineBreak") then
      saw_break = true
    elseif saw_break then
      table.insert(content, item)
    else
      table.insert(title, item)
    end
  end

  return trim_inline_edges(title), trim_inline_edges(content)
end

local function callout_title(kind, inlines)
  if #inlines > 0 then
    return inlines
  end

  return { pandoc.Str(callout_titles[kind] or kind) }
end

function Para(el)
  if #el.content ~= 1 or el.content[1].t ~= "Str" then
    return nil
  end

  local target, size = parse_obsidian_image(el.content[1].text)
  if not target then
    return nil
  end

  return pandoc.Para({ make_image(target, size) })
end

function BlockQuote(el)
  if #el.content == 0 then
    return nil
  end

  local first = el.content[1]
  if first.t ~= "Para" and first.t ~= "Plain" then
    return nil
  end

  if #first.content == 0 or first.content[1].t ~= "Str" then
    return nil
  end

  local kind = parse_callout_marker(first.content[1].text)
  if not kind then
    return nil
  end

  local title_inlines, first_content = split_callout_head(first.content)
  local content_blocks = {}

  if #first_content > 0 then
    table.insert(content_blocks, pandoc.Para(first_content))
  end

  for i = 2, #el.content do
    table.insert(content_blocks, el.content[i])
  end

  local title = pandoc.Div(
    { pandoc.Plain(callout_title(kind, title_inlines)) },
    pandoc.Attr("", { "obsidian-callout-title" })
  )
  local content = pandoc.Div(
    content_blocks,
    pandoc.Attr("", { "obsidian-callout-content" })
  )

  return pandoc.Div(
    { title, content },
    pandoc.Attr("", { "obsidian-callout", "obsidian-callout-" .. kind })
  )
end

function Str(el)
  local target, size = parse_obsidian_image(el.text)
  if not target then
    return nil
  end

  return make_image(target, size)
end
