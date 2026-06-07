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

function Str(el)
  local target, size = parse_obsidian_image(el.text)
  if not target then
    return nil
  end

  return make_image(target, size)
end
