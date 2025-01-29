import numpy as np

def call_mojo_print(mojo_print, a: int):
    print('a: ' + String(a))
    res = mojo_print(123)
    for i in range(10):
        res = mojo_print(res)


def call_sum(sum):
    elements = 100
    array = np.random.random(elements)
    
    res = sum(array.ctypes.data,elements)
    _ = array
    
    print(res)

    #notes:
    #print(array.dtype)   #float64
    #print(array.strides) #8