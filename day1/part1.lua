#!/usr/bin/env lua

function CalcFuel(mass)
    return math.floor(mass / 3) -2
end

function TotalFuel(filepath)
    local sum = 0
    for mass in io.lines(filepath) do
        sum = sum + CalcFuel(mass)
    end
    return sum
end

if(#arg > 0) then
    print("total fuel required: " .. TotalFuel(arg[1]))
else
    print("usage: ./day1.lua inputfile")
end