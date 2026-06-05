TycoonCore = TycoonCore or {}

local logger = {}

local function formatMessage(level, moduleName, text, ...)
    local ok, rendered = pcall(string.format, tostring(text or ''), ...)
    local message = ok and rendered or tostring(text or '')
    return ('[%s][%s] %s'):format(level, tostring(moduleName or 'core'), message)
end

function logger.log(moduleName, text, ...)
    print(formatMessage('INFO', moduleName, text, ...))
end

function logger.success(moduleName, text, ...)
    print(formatMessage('OK', moduleName, text, ...))
end

function logger.error(moduleName, text, ...)
    print(formatMessage('ERR', moduleName, text, ...))
end

function logger.create(moduleName)
    return {
        log = function(text, ...)
            logger.log(moduleName, text, ...)
        end,
        success = function(text, ...)
            logger.success(moduleName, text, ...)
        end,
        error = function(text, ...)
            logger.error(moduleName, text, ...)
        end,
    }
end

TycoonCore.Logger = logger

return logger
