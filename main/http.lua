---@diagnostic disable: lowercase-global

http = http or {}

local function unsupported()
	return nil
end

---Client-side SRCC currently provides no async HTTP worker pipeline.
---@param _scheme string
---@param _path string
---@param _headers table<string, string>
---@param callback fun(response: HTTPResponse|nil)
function http.get(_scheme, _path, _headers, callback)
	if callback then
		callback(nil)
	end
end

---Client-side SRCC currently provides no async HTTP worker pipeline.
---@param _scheme string
---@param _path string
---@param _headers table<string, string>
---@param _body string
---@param _contentType string
---@param callback fun(response: HTTPResponse|nil)
function http.post(_scheme, _path, _headers, _body, _contentType, callback)
	if callback then
		callback(nil)
	end
end

http.getSync = unsupported
http.postSync = unsupported

return http
