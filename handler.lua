local plugin = require("kong.plugins.base_plugin"):extend()

local cjson = require "cjson"
local req_read_body = ngx.req.read_body
local req_get_body_data = ngx.req.get_body_data
local req_set_header = ngx.req.set_header
local pcall = pcall

local function parse_json(body)
  if body then
    local status, res = pcall(cjson.decode, body)
    if status then
      return res
    end
  end
end


local function read_current_value(conf)
  local path = conf.current_value.json_path_or_header_name_or_querystring
  if conf.current_value.current_value_type ==  'querystring' then
    local args =  ngx.req.get_uri_args()
    return args[path]
  end

  if conf.current_value.current_value_type ==  'headers' then
    local headers = ngx.req.get_headers()
    return headers[path]
  end
  
  if conf.current_value.current_value_type ==  'body' then
    req_read_body()
    
    local parameters = parse_json(req_get_body_data())
    if parameters == nil then
      ngx.log(ngx.DEBUG, "parameters are NIL")
    end

    local table = parameters
    for str in string.gmatch(path, "([^.]+)") do
      local value = table[str]
      if (value == nil) then
        return nil
      end
      table = value
    end
    return table
  end

end


local dump = function(...)
  local info = debug.getinfo(2) or {}
  local input = {n = select("#", ...), ...}
  local write = require("pl.pretty").write
  local serialized
  if input.n == 1 and type(input[1]) == "table" then
    serialized = "(" .. type(input[1]) .. "): " .. write(input[1])
  elseif input.n == 1 then
    serialized = "(" .. type(input[1]) .. "): " .. tostring(input[1]) .. "\n"
  else
    local n
    n, input.n = input.n, nil
    serialized = "(list, #" .. n .. "): " .. write(input)
  end

  ngx.log(
    ngx.WARN,
    "\027[31m\n",
    "function '",
    tostring(info.name),
    ":",
    tostring(info.currentline),
    "' in '",
    tostring(info.short_src),
    "' wants you to know:\n",
    serialized,
    "\027[0m"
  )
end

local function modify_upstream(host, port, uri)
  ngx.log(ngx.DEBUG, "modifying upstream ...")

  if host ~= nil then
    ngx.ctx.balancer_address.host = host
  end
  if port ~= nil then
    ngx.ctx.balancer_address.port = port
  end
  if uri ~= nil and string.len(uri) > 0 then
    ngx.var.upstream_uri = uri
  end
end

function plugin:access(conf)
  
  local current_value = read_current_value(conf)

  local host = conf.upstream.host
  local port = conf.upstream.port
  local uri = conf.upstream.path

  if conf.value_check.value_check_type == "equals" then
    if current_value == conf.value_check.value then
      modify_upstream(host, port, uri)
    end
  end
  if conf.value_check.value_check_type == "exists" and current_value ~= nil then
    modify_upstream(host, port, uri)
  end
  if conf.value_check.value_check_type == "missing" and current_value == nil then
    modify_upstream(host, port, uri)
  end
  if conf.value_check.value_check_type == "match expression" and conf.value_check.value ~= nil and current_value ~= nil and string.find(current_value, conf.value_check.value) then
    modify_upstream(host, port, uri)
  end
end

return plugin
