--定义一个名为module的模块
module = {}

module.constant = "常量"

function module.func1()
    io.write("这是一个公有函数")
end

local function func2()
    io.write("这是一个私有函数\n")
end
dsf 
function module.func3()
    func2()
end

return module
