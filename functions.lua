---------------------------------
-- Author: Reyn
-- Date: 2016-05-12 15:55:39
-- Content: CSV 转 Lua 方法集合
---------------------------------

local _M        = {}
local GBK       = require('gbk')
local CONFIG    = require('config')

local toutf8    = GBK.toutf8
_M.CONFIG       = CONFIG
_M.GBK          = GBK
local open      = io.open
local popen     = io.popen
local strlen    = string.len
local strbyte   = string.byte
local strsub    = string.sub
local strformat = string.format
local strrep    = string.rep
local strgsub   = string.gsub
local strfind   = string.find
local tconcat   = table.concat
local tsort     = table.sort

--[[
    分隔符定义
]]--
local Delimiter = {
    Dot      = ',',
    NewLine  = '\n',
    Tab      = '\t',
    Vertiline= '|',
    Underline= '_',
}
_M.Delimiter = Delimiter

--[[
    获得文件信息
]]--
local function pathinfo(path)
    local pos = strlen(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = strbyte(path, pos)
        if b == 46 then     -- 46 = char '.'
            extpos = pos
        elseif b == 47 then -- 47 = char '/'
            break
        end
        pos = pos - 1
    end
    extpos = extpos - pos

    local dirname  = strsub(path, 1, pos)
    local filename = strsub(path, pos + 1)
    local basename = strsub(filename, 1, extpos - 1)
    local extname  = strsub(filename, extpos)
    return {
        dirname  = dirname,
        filename = filename,
        basename = basename,
        extname  = extname
    }
end
_M.pathinfo = pathinfo

--[[
    将表插入到另一个表
]]--
local function insertto(dest, src, begin)
    if not src then return end

    begin = begin or 0
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end
_M.insertto = insertto

--[[
    获得表的键表
]]--
local function tkeys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end
_M.tkeys = tkeys

--[[
    获得表的值表
]]--
local function tvalues(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end
_M.tvalues = tvalues

--[[
    分割字符串
]]--
local function split(source, delimiter)
    source    = tostring(source)
    delimiter = tostring(delimiter)
    local match  = strformat('[^%s]*.', delimiter)
    local ret = {}
    strgsub(source, match, function (word)
        ret[#ret + 1] = strgsub(word, delimiter, '')
    end)
    return ret
end
_M.split = split

--[[
    使用‘,’分割字符串
]]--
local function splitDot(str)
    return split(str, Delimiter.Dot)
end
_M.splitDot  = splitDot

--[[
    使用‘\n’分割字符串
]]--
local function splitLine(str)
    return split(str, Delimiter.NewLine)
end
_M.splitLine = splitLine

--[[
    字符串转换成 lua 值
]]--
local function value2Str(value, level, indexTab, isNeedIndex)
    indexTab        = indexTab or {}
    local ret       = {}
    local level     = level or 0
    local space     = strrep(Delimiter.Tab, level)
    local nextSpace = strrep(Delimiter.Tab, level + 1)
    local valType   = type(value)

    if valType == 'string' then
        ret[#ret+1] = '"'
        ret[#ret+1] = value
        ret[#ret+1] = '"'
    elseif valType == 'table' then
        ret[#ret+1] = '{'..Delimiter.NewLine
        local keys = tkeys(value)
        tsort(keys,function (a, b)
            local typeA = type(a)
            local typeB = type(b)
            if typeA == typeB then
                return a < b
            end
            return typeA == 'number'
        end)
        for _, key in ipairs(keys) do
            local val = value[key]
            ret[#ret+1] = nextSpace

            local keyval= value2Str(key, level+1, indexTab)
            if isNeedIndex then
                ret[#ret+1] = '['
                insertto(ret, keyval)
                ret[#ret+1] = '] = '
            else
                if not(type(key) == 'number' and key < 10000) then
                    ret[#ret+1] = '['
                    insertto(ret, keyval)
                    ret[#ret+1] = '] = '
                end
            end

            insertto(ret, value2Str(val, level+1, indexTab))
            ret[#ret+1] = Delimiter.Dot .. Delimiter.NewLine
        end
        ret[#ret+1] = space
        ret[#ret+1] = '}'
    elseif valType == 'number' then
        ret[#ret+1] = value
    else
        ret[#ret+1] = tostring(value)
    end
    return ret
end
_M.value2Str = value2Str

--[[
    获得转换后的字符串
]]--
local function getConvertStr(value)
    local values  = tconcat(value2Str(value),'')
    local retstr  = strformat("%s%s",'',values)
    return retstr
end
_M.getConvertStr = getConvertStr

--[[
    写到 lua 文件
]]--
local function outputLua(name, content)
    local lua_path  = CONFIG.PATH.LUA_CONF
    local filename  = strformat('%s%s.lua', lua_path, name)
    local file = open(filename, 'w')
    local text = 'local %s = %s\n\nreturn %s'
    file:write(strformat(text, name, content, name))
    file:close()
end
_M.outputLua = outputLua

--[[
    读取目录下的文件，不包括子目录
    如果要读取子目录，需要到 config 文件中添加子目录路径
]]--
local function getDirFiles(dir)
    local file    = popen('ls '..dir, 'r')
    local content = file:read('*a')
    local fileStr = splitLine(content)

    local fileLst = {}
    for i,name in ipairs(fileStr) do
        local filename = dir..name
        fileLst[#fileLst+1] = filename
    end

    return fileLst
end
_M.getDirFiles = getDirFiles

--[[
    检查数值是否为空，若不为空，则执行 callfun
]]--
local function checkValue(val, callfun)
    if not val then return nil end
    if callfun then return callfun(val) end
    return nil
end
_M.checkValue = checkValue

--[[
    打开并读取文件内容
]]
local function getFileInfo(filepath)
    local fileP   = open(filepath, 'r')
    local content = toutf8(fileP:read('*a'))
    fileP:close()
    return content
end
_M.getFileInfo = getFileInfo

--[[
    获取字符串至倒数第二个字符
]]--
local function subStrLastTwo(str)
    return strsub(str, 1, -2)
end
_M.subStrLastTwo = subStrLastTwo

--[[
    转换字符串为数值，若失败则返回原字符串
]]--
local function convertNumber(str)
    local _,endIdx = strfind(str, '%d+')
    if endIdx and endIdx == strlen(str) then
        str = tonumber(str)
    end
    return str
end
_M.convertNumber = convertNumber

--[[
    格式化表数据，使区分字符串和数值
]]--
local function formatTab(tab)
    for i,val in ipairs(tab) do
        tab[i] = convertNumber(val)
    end
    return tab
end
_M.formatTab = formatTab

--[[
    判断表中是否包含值
]]--
local function isContain(tab, val)
    for _,v in pairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end
_M.isContain = isContain

--[[
    转换类型定义
]]--
local ConvertType = {
    Normal       = 0,
    Key2Value    = 1,
    Column2Value = 2,
}
_M.ConvertType = ConvertType

--[[
    组织文件内容返回数据
]]--
local function OrganizeData(filepath, options)
    options = options or {}
    local beginLine  = options.beginLine  or 2                      -- 一般第1行是键名，所以从第2行开始取数据
    local primaryKey = options.primaryKey or 1                      -- 作为索引的主键
    local tabKeys    = options.tabKeys or {}                        -- 需要转换为 table 的键值
    local delimiter  = options.delimiter   or Delimiter.Vertiline   -- 需要转换为 table 的键值对应的分隔符
    local convertType= options.convertType or ConvertType.Normal    -- 转换类型

    local content = getFileInfo(filepath)
    local lines   = splitLine(content)
    local ret = {}

    if convertType == ConvertType.Normal then
        local keys  = splitDot(subStrLastTwo(lines[1]))
        for level1, line in ipairs(lines) do
            if level1 >= beginLine then
                local tab = checkValue(subStrLastTwo(line), splitDot)
                if #tab > 0 then
                    local level2arr = {}
                    local primaryVal
                    for level2, val in ipairs(tab) do
                        local key = keys[level2]
                        if val ~= '' then
                            if isContain(tabKeys, key) then
                                val = formatTab(split(val, delimiter))
                            else
                                val = convertNumber(val)
                            end
                            level2arr[key] = val
                        end
                        if key == primaryKey then
                            primaryVal = val
                        end

                    end
                    primaryVal = primaryVal or (level1-1)
                    ret[primaryVal] = level2arr
                end
            end
        end
    elseif convertType == ConvertType.Key2Value then
        for i,line in ipairs(lines) do
            local splitStr = splitDot(subStrLastTwo(line))
            local key,value= splitStr[1], splitStr[2]
            ret[key] = value
        end
    elseif convertType == ConvertType.Column2Value then
        local keys = splitDot(subStrLastTwo(lines[1]))
        local tab  = {}
        for i,v in ipairs(keys) do
            tab[keys[i]] = {}
        end
        for i,line in ipairs(lines) do
            if i >= beginLine then
                local splitStr = splitDot(subStrLastTwo(line))
                for level, str in ipairs(splitStr) do
                    table.insert(tab[keys[level]], str)
                end
            end
        end
        ret = tab
    end
    return ret
end
_M.OrganizeData = OrganizeData

return _M
