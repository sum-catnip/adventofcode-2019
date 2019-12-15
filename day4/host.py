#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# to run this youll need to install pyopencl
# pip install pyopencl
# youll also have to install your gpu specific opencl sdk
# those can be easily found with a bit of googleing
# if youre on windows, remember to set the INCLUDE and LIB env variables
# to your sdk's include and lib directories

# sample run:
# > python .\host.py
# input range: 245182-790572
# Choose platform:
# [0] <pyopencl.Platform 'NVIDIA CUDA' at 0x1cf287e4e30>
# Choice [0]:0
# Set the environment variable PYOPENCL_CTX='0' to avoid being asked again.
# =========== part1
# done. calculation took 0.0070116519927978516 seconds
# there are 1099 possible pins

# =========== part2
# done. calculation took 0.003000974655151367 seconds
# there are 710 possible pins


from __future__ import absolute_import, print_function
import time
import numpy as np
import pyopencl as cl

inrange = input('input range: ').split('-')
pins = np.array(range(int(inrange[0]), int(inrange[1]) +1), dtype=np.int32)

ctx = cl.create_some_context()
queue = cl.CommandQueue(ctx)

mf = cl.mem_flags
pins_cl = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=pins)

with open('part1.cl', 'r') as f:
    prg = cl.Program(ctx, f.read()).build()

res_cl = cl.Buffer(ctx, mf.WRITE_ONLY, pins.nbytes)
perf = time.time()
prg.check_all_pins(queue, pins.shape, None, pins_cl, res_cl)
res_np = np.empty_like(pins)
cl.enqueue_copy(queue, res_np, res_cl)

print(f'=========== part1')
print(f'done. calculation took {time.time() - perf} seconds')
print(f'there are {np.sum(res_np)} possible pins\n')


with open('part2.cl', 'r') as f:
    prg = cl.Program(ctx, f.read()).build()

res_cl = cl.Buffer(ctx, mf.WRITE_ONLY, pins.nbytes)
perf = time.time()
prg.check_all_pins(queue, pins.shape, None, pins_cl, res_cl)
res_np = np.empty_like(pins)
cl.enqueue_copy(queue, res_np, res_cl)

print(f'=========== part2')
print(f'done. calculation took {time.time() - perf} seconds')
print(f'there are {np.sum(res_np)} possible pins')
