-- Renders an interactive, tabbed event schedule from an external YAML file.
--
--   {{< schedule file="data/schedule.yml" >}}
--
-- The YAML file is parsed by wrapping its contents in `---` fences and
-- handing it to Pandoc's markdown/YAML reader (Lua has no built-in
-- YAML parser).
--
-- The tabset itself is built with quarto.Tabset()/quarto.Tab()

local function str(v)
  if v == nil then
    return nil
  end
  return pandoc.utils.stringify(v)
end

-- Escapes HTML special characters so YAML content (titles,
-- descriptions, lead names, types) can't be misparsed as HTML markup
local function html_escape(s)
  if s == nil then
    return nil
  end
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  s = s:gsub("'", "&#39;")
  return s
end

local function read_yaml_file(path)
  local file = io.open(path, "r")
  if not file then
    error("schedule shortcode: could not open file '" .. path .. "'")
  end
  local content = file:read("a")
  file:close()
  local wrapped = "---\n" .. content .. "\n---\n"
  -- Disable `raw_html` and `smart`: without them, `<...>`-looking text stays
  -- literal (instead of becoming a raw-HTML node that `stringify` drops) and
  -- straight quotes stay straight (instead of becoming curly `Quoted` nodes).
  -- That keeps `str()` below a faithful, literal read of the YAML scalars.
  local doc = pandoc.read(wrapped, "markdown-raw_html-smart+yaml_metadata_block")
  return doc.meta
end

-- Row color comes from setting `type:` in the YAML and set color in 
-- schedule.css using `.sched-<type>` rules); sessions without one get the
-- default "session" styling.
local function session_type(session)
  local explicit = str(session.type)
  if explicit and explicit ~= "" then
    return html_escape(explicit)
  end
  return "session"
end

local function leads_text(session)
  if session.leads == nil or #session.leads == 0 then
    return "\xe2\x80\x94" -- em dash
  end
  local names = {}
  for _, lead in ipairs(session.leads) do
    table.insert(names, html_escape(str(lead)))
  end
  return table.concat(names, ", ")
end

local function session_row(session)
  local stype = session_type(session)
  local title = html_escape(str(session.title) or "")
  local description = html_escape(str(session.description))
  local time = str(session.time) or ""

  local title_html
  if description and description ~= "" then
    title_html = string.format(
      "<strong>%s</strong><br><span class='text-muted'>%s</span>",
      title, description
    )
  else
    title_html = string.format("<strong>%s</strong>", title)
  end

  return string.format(
    '<tr class="sched-%s">\n<td>%s</td><td>%s</td><td>%s</td>\n</tr>',
    stype, time, title_html, leads_text(session)
  )
end

local function day_table(day)
  local rows = {
    '<table class="table caption-top schedule-table">',
    "<thead><tr><th>Time</th><th>Session</th><th>Leads</th></tr></thead>",
    "<tbody>",
  }
  for _, session in ipairs(day.sessions) do
    table.insert(rows, session_row(session))
  end
  table.insert(rows, "</tbody></table>")
  -- Wrap in a RawBlock (rather than returning a plain string) so this goes
  -- to the page verbatim. quarto.Tab() would otherwise re-parse a string
  -- `content` as markdown, an extra parsing pass we don't need
  return pandoc.Blocks({ pandoc.RawBlock("html", table.concat(rows, "\n")) })
end

local function schedule_shortcode(args, kwargs)
  local path = kwargs["file"]
  if not path and args[1] then
    path = str(args[1])
  end
  if not path then
    error("schedule shortcode: requires a `file` argument, e.g. {{< schedule file=\"data/schedule.yml\" >}}")
  end

  local meta = read_yaml_file(path)
  local timezone = str(meta.timezone) or ""

  local tabs = {}
  for _, day in ipairs(meta.days) do
    table.insert(tabs, quarto.Tab({
      title = string.format("%s (%s)", str(day.title) or "", str(day.date) or ""),
      content = day_table(day),
    }))
  end

  local tabset = quarto.Tabset({
    level = 2,
    tabs = pandoc.List(tabs),
    attr = pandoc.Attr("", { "panel-tabset" }, {}),
  })

  quarto.doc.add_html_dependency({
    name = "schedule",
    version = "1.0.0",
    stylesheets = { "schedule.css" },
  })

  local intro = pandoc.Para({
    pandoc.Str("All times listed below are "),
    pandoc.Strong({ pandoc.Str(timezone) }),
    pandoc.Str("."),
  })

  return { intro, tabset }
end

return {
  ["schedule"] = schedule_shortcode,
}
