local create_request = function(host)
    local request = {
        method = "GET",
        host = host,
        path = "",
        uri = {},
        header = {},
        body = nil,
    }

    -- Sets request method
    function request.set_method(method)
        request.method = method
        return request
    end

    function request.set_path(path)
        request.path = path
        return request
    end

    function request.set_uri(uri)
        request.uri = uri
        return request
    end

    function request.set_header(name, value)
        request.header[name] = value
        return request
    end

    function request.set_body(body)
        -- request.set_header("content-length", string.len(body))
        request.body = body
        return request
    end

    function request.send()
        local url = request.host .. request.path
        local cmd = { "curl", "-X", request.method, url }

        for name, value in pairs(request.header) do
            cmd[#cmd + 1] = string.format("-H'%s: %s'", name, value)
        end

        if request.body then
            cmd[#cmd + 1] = string.format("-d '%s'", request.body)
        end

        print(table.concat(cmd, " "))

        local handle = io.popen(table.concat(cmd, " "))
        if not handle then
            return nil
        end

        local result = handle:read("*a")
        handle:close()

        return result
    end

    return request
end

local result = create_request("https://httpbin.org")
    .set_method("POST")
    .set_path("/post")
    .set_header("Content-Type", "application/json")
    .set_header("random", "hello")
    .set_body('{"hello":"world"}')
    .send()

print(result)


return {
    request = create_request,
}
