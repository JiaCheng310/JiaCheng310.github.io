local function parse_obsidian_image(text)
  text = text:gsub("^%s+", ""):gsub("%s+$", "")

  local target, size = text:match("^%!%[%[([^%]|]+)%|([^%]]+)%]%]$")
  if target then
    return target, size
  end

  target = text:match("^%!%[%[([^%]]+)%]%]$")
  return target, nil
end

local function normalize_size(size)
  if not size then
    return nil
  end

  size = size:gsub("^%s+", ""):gsub("%s+$", "")
  local numeric = size:match("^(%d+)$")
  if numeric then
    return numeric .. "px"
  end

  return size
end

local function normalize_target(target)
  target = target:gsub("^%s+", ""):gsub("%s+$", "")

  if target:match("^https?://") or target:match("^/") or target:match("^%.%.?/") or target:find("/") then
    return target
  end

  if target:lower():match("%.gif$") or target:lower():match("%.png$") or target:lower():match("%.jpe?g$") or target:lower():match("%.webp$") or target:lower():match("%.svg$") then
    return "images/" .. target
  end

  return target
end

local function make_image(target, size)
  local attrs = {
    ["fig-align"] = "center"
  }

  size = normalize_size(size)
  if size then
    attrs["width"] = size
  end

  local attr = pandoc.Attr("", { "obsidian-image" }, attrs)
  return pandoc.Image({}, normalize_target(target), "", attr)
end

local function has_class(el, class)
  for _, value in ipairs(el.classes or {}) do
    if value == class then
      return true
    end
  end

  return false
end

local function image_info_from_block(block)
  if block.t ~= "Para" and block.t ~= "Plain" then
    return nil
  end

  if #block.content == 1 and block.content[1].t == "Image" and has_class(block.content[1], "obsidian-image") then
    local image = block.content[1]
    return {
      target = normalize_target(image.src or image.target),
      size = normalize_size(image.attributes and image.attributes.width)
    }
  end

  local text = pandoc.utils.stringify(block)
  local target, size = parse_obsidian_image(text)
  if not target then
    return nil
  end

  return {
    target = normalize_target(target),
    size = normalize_size(size)
  }
end

local function is_gif(info)
  return info and info.target:lower():match("%.gif$")
end

local function escape_html(value)
  value = value or ""
  value = value:gsub("&", "&amp;")
  value = value:gsub("<", "&lt;")
  value = value:gsub(">", "&gt;")
  value = value:gsub('"', "&quot;")
  return value
end

local function make_image_row(infos)
  local html = { '<div class="obsidian-image-row">' }

  for _, info in ipairs(infos) do
    local style = ""
    if info.size then
      style = ' style="max-width:' .. escape_html(info.size) .. ';"'
    end
    table.insert(html, '  <div class="obsidian-image-row-item"' .. style .. '><img src="' .. escape_html(info.target) .. '" alt=""></div>')
  end

  table.insert(html, "</div>")
  return pandoc.RawBlock("html", table.concat(html, "\n"))
end

local function image_infos_from_inlines(inlines)
  local infos = {}

  for _, item in ipairs(inlines) do
    if item.t == "Space" or item.t == "SoftBreak" or item.t == "LineBreak" then
      -- Image-only paragraphs often contain line breaks between images.
    elseif item.t == "Str" then
      local target, size = parse_obsidian_image(item.text)
      if not target then
        return nil
      end
      table.insert(infos, {
        target = normalize_target(target),
        size = normalize_size(size)
      })
    elseif item.t == "Image" and has_class(item, "obsidian-image") then
      table.insert(infos, {
        target = normalize_target(item.src or item.target),
        size = normalize_size(item.attributes and item.attributes.width)
      })
    else
      return nil
    end
  end

  if #infos == 0 then
    return nil
  end

  return infos
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
  local target, size = parse_obsidian_image(pandoc.utils.stringify(el))
  if target then
    return pandoc.Para({ make_image(target, size) })
  end

  local infos = image_infos_from_inlines(el.content)
  if not infos then
    return nil
  end

  local all_gifs = true
  for _, info in ipairs(infos) do
    if not is_gif(info) then
      all_gifs = false
      break
    end
  end

  if #infos >= 2 and all_gifs then
    return make_image_row(infos)
  end

  local images = {}
  for _, info in ipairs(infos) do
    table.insert(images, make_image(info.target, info.size))
  end

  return pandoc.Para(images)
end

function Pandoc(doc)
  local blocks = {}
  local i = 1

  while i <= #doc.blocks do
    local info = image_info_from_block(doc.blocks[i])

    if is_gif(info) then
      local group = { info }
      local j = i + 1

      while j <= #doc.blocks do
        local next_info = image_info_from_block(doc.blocks[j])
        if not is_gif(next_info) then
          break
        end

        table.insert(group, next_info)
        j = j + 1
      end

      if #group >= 2 then
        table.insert(blocks, make_image_row(group))
        i = j
      else
        table.insert(blocks, pandoc.Para({ make_image(info.target, info.size) }))
        i = i + 1
      end
    elseif info then
      table.insert(blocks, pandoc.Para({ make_image(info.target, info.size) }))
      i = i + 1
    else
      table.insert(blocks, doc.blocks[i])
      i = i + 1
    end
  end

  doc.blocks = blocks
  return doc
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
