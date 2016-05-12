---------------------------------
-- Author: Reyn
-- Date: 2016-05-12 15:57:07
-- Content: CSV 转 Lua 开始
---------------------------------

local Tools         = require('functions')
local GBK           = Tools.GBK
local PATH          = Tools.CONFIG.PATH
local ConvertType   = Tools.ConvertType
local OrganizeData  = Tools.OrganizeData
local getConvertStr = Tools.getConvertStr
local outputLua     = Tools.outputLua
local getPathInfo   = Tools.pathinfo
local getDirFiles   = Tools.getDirFiles

--[[
    适合普通转换的情况，即默认的转换方法
]]--
local Common = OrganizeData

--[[
    适合需要将其中多个键值转换为 table 的情况
]]--
local Speech = function(data)
    return OrganizeData(data, {tabKeys={'nextIds'}, delimeter='|'})
end

--[[
    适合将其中某个键作为索引键的情况
]]--
local PrimaryKey = function(data)
    return OrganizeData(data, {primaryKey='ID', tabKeys={'nextIds'}, delimeter='|'})
end

--[[
    适合第一列为键，第二列为值的情况
]]
local Key2Value = function(data)
    return OrganizeData(data, {beginLine=1, convertType=ConvertType.Key2Value})
end

--[[
    适合第一行为键，对应列下为值的情况
]]
local Column2Value = function(data)
    return OrganizeData(data, {convertType=ConvertType.Column2Value})
end

--[[
    待转换的文件名 => 输出的文件名
]]--
local ReadyFiles = {
    ['Speech']      = 'Speech',
    ['Playername']  = 'PlayerName',
    ['UItext']      = 'UItext',
}

--[[
    输出文件对应使用的转换方法
]]--
local UseMethods = {
    Speech          = Speech,
    CompanyName     = Column2Value,
    UItext          = Key2Value,
}

--[[
    获得输出的文件名
]]--
local function getOutPutName(basename)
    local files = ReadyFiles
    local name  = basename
    for k,v in pairs(files) do
        if k == basename then
            return v
        end
    end
    return name
end

--[[
    开始转换操作
]]
local function beginConvert()
    local files = getDirFiles(PATH.CSV_CONF)
    for i,filename in ipairs(files) do
        local basename = getPathInfo(filename).basename
        local outname  = getOutPutName(basename)
        local useMethod= UseMethods[outname] or Common
        local orgdata  = useMethod(filename)
        local outdata  = getConvertStr(orgdata)
        outputLua(outname, outdata)
    end
end

beginConvert()
