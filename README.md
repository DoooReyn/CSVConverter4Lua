#CSVConverter

## 介绍
功能：将 `CSV` 文件转换为 `Lua` 格式并输出。
- 支持自定义索引键；
- 支持归并列；
- 支持自定义键值转换为 `table`；

主要文件说明：
- `config.lua` : 保存 `CSV` 、`Lua`、`PHP` 存放或输出的路径
- `functions.lua` : 通用转换方法
- `converter.lua` : 执行转换入口

## 使用方法
- 依赖：[luagbk](https://github.com/starwing/luagbk)
    - 安装：`luarocks install luagbk`
- 示例：详见 `converter.lua` 中的示例。

## 计划
1. 支持从 `CSV` 文件中提取中文并输出为单独文件，保存到对应目录下的 `lang` 目录；
2. 支持将 `CSV` 转换为 `PHP`;
3. 自动判断 `CSV` 编码**（当前默认 CSV 为 GBK 编码）**。
