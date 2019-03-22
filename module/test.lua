--[[
    返回一个由模块常量或函数组成的 table，并且还会
定义一个包含该 table 的全局变量。
]] --
require("./module/module")

print(module.constant)
print(module.func1())
print(module.func3())
