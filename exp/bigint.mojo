# https://github.com/bgreni/MojoBigInt/blob/main/bignum/bigint.mojo

# from math import max, min, abs
from memory import memcpy, memset_zero, memcmp, UnsafePointer

alias Limb = Int8
alias Type = Int8
alias Data = UnsafePointer[Type]
alias BASE = 10
alias BASE_TYPE = Int8(BASE)


fn swap(mut lhs: BigInt, mut rhs: BigInt):
    var temp = lhs
    lhs = rhs
    rhs = temp


struct BigInt:
    var data: Data
    var capacity: Int
    var sign: Bool
    var size: Int

    fn __init__(out self):
        self.sign = False
        self.size = 1
        self.capacity = 4
        self.data = self.allocate(self.capacity)
        self.store(0, 0)

    fn __init__(out self, init_val: Int):
        var val = init_val
        self.sign = val < 0
        if self.sign:
            val = -val
        self.size = 0
        self.capacity = 4
        self.data = self.allocate(self.capacity)
        while val > 0:
            self.push_digit(val % 10)
            val /= 10

    fn __init__(out self, init_val: String):
        self.sign = init_val[0] == "-"
        if self.sign:
            self.size = len(init_val) - 1
        else:
            self.size = len(init_val)
        self.capacity = self.size * 2
        self.data = self.allocate(self.capacity)
        var bump: Int = 1 if self.sign else 0
        for i in range(self.size):
            try:
                self.store(self.eindex() - i, atol(init_val[i + bump]))
            except:
                pass

    fn __del__(owned self):
        self.data.free()

    @always_inline
    @staticmethod
    fn allocate(size: Int) -> Data:
        return Data.alloc(size)

    @always_inline
    fn load(self, ind: Int) -> Limb:
        return self.data.load(ind)

    @always_inline
    fn store(mut self, ind: Int, val: Limb):
        self.data.store(ind, val)

    fn push_digit(mut self, digit: Limb):
        if self.size == self.capacity:
            self.grow()
        self.store(self.size, digit)
        self.size += 1

    fn pop_digit(mut self):
        self.size -= 1

    @always_inline
    fn __getitem__(self, ind: Int) -> Limb:
        return self.load(ind)

    @always_inline
    fn __setitem__(mut self, ind: Int, val: Limb):
        self.store(ind, val)

    fn __copyinit__(mut self, other: BigInt):
        self.sign = other.sign
        self.capacity = other.capacity
        self.size = other.size
        self.data = self.allocate(self.capacity)
        memcpy(self.data, other.data, self.size)

    fn add(mut self, other: BigInt):
        var rhs = other
        if not self.sign and rhs.sign:
            rhs.sign = False
            self.sub(rhs)
            return
        if self.sign and not rhs.sign:
            self.sign = False
            swap(self, rhs)
            self.sub(rhs)
            return

        if rhs > self:
            swap(self, rhs)

        var carry: Limb = 0
        if self.size < rhs.size:
            self.grow(rhs.size)

        for i in range(rhs.size):
            var temp = self[i] + rhs[i] + carry
            self[i] = temp % BASE
            carry = temp / BASE
        if carry != 0:
            self.push_digit(carry)

        self.sign = self.sign and rhs.sign

    fn __add__(self, other: BigInt) -> Self:
        var out = self
        out.add(other)
        return out

    fn __iadd__(mut self, other: BigInt):
        self.add(other)

    fn sub(mut self, other: BigInt):
        var rhs = other

        if not self.sign and rhs.sign:
            rhs.sign = False
            self.add(rhs)
            return
        elif self.sign and not rhs.sign:
            rhs.sign = True
            self.add(rhs)
            return
        elif self.sign and rhs.sign:
            self.sign = False
            rhs.sign = False
            swap(self, rhs)
            self.sub(rhs)
            return

        if rhs > self:
            swap(self, rhs)
            self.neg()

        var borrow: Limb = 0

        if self.size < rhs.size:
            self.grow(rhs.size)

        for i in range(rhs.size):
            var temp = self[i] - rhs[i] - borrow
            var need_borrow = temp < 0
            self[i] = (temp + BASE) % BASE
            borrow = Limb(1 if need_borrow else 0)
        self[self.eindex()] -= borrow
        if self.last() == 0:
            while self.last() == 0 and self.size > 1:
                self.pop_digit()

    fn __sub__(self, other: BigInt) -> Self:
        var out = self
        out.sub(other)
        return out

    fn __isub__(mut self, other: BigInt):
        self.sub(other)

    fn mul(mut self, other: BigInt):
        var outSign = not (self.sign ^ other.sign)

        if not self or not other:
            self = BigInt(0)

    fn grow(mut self, size: Int = 0):
        var new_cap = self.capacity * 2 if size == 0 else size
        var new_data = self.allocate(new_cap)
        memset_zero(new_data, new_cap)
        memcpy(new_data, self.data, self.size)
        self.data.free()
        self.data = new_data
        self.capacity = new_cap

    fn shrink(mut self):
        var new_data = self.allocate(self.size)
        memcpy(new_data, self.data, self.size)
        self.data.free()
        self.data = new_data

    @always_inline
    fn last(self) -> Limb:
        return self[self.eindex()]

    fn eindex(self) -> Int:
        return self.size - 1

    @always_inline
    fn __len__(self) -> Int:
        return self.size

    fn to_string(self) -> String:
        var s = String()
        if self.sign:
            s += "-"
        for i in range(self.eindex(), -1, -1):
            var v = self[i]
            s += chr(ord("0") + int(v))
        return s

    fn print(self):
        print(self.to_string())

    fn __eq__(self, other: BigInt) -> Bool:
        if self.sign != other.sign:
            return False
        if self.size != other.size:
            return False
        return memcmp[Type](self.data, other.data, self.size) == 0

    fn __lt__(self, other: BigInt) -> Bool:
        if self.sign and not other.sign:
            return True
        if not self.sign and other.sign:
            return False
        if self.size < other.size:
            return True
        if self.size > other.size:
            return False

        for i in range(self.eindex(), -1, -1):
            var n1 = self[i]
            var n2 = other[i]
            if n1 < n2:
                return True
            elif n2 < n1:
                return False
        return False

    fn __gt__(self, other: BigInt) -> Bool:
        if self.sign and not other.sign:
            return False
        if not self.sign and other.sign:
            return True
        if self.size > other.size:
            return True
        if self.size < other.size:
            return False

        for i in range(self.eindex(), -1, -1):
            var n1 = self[i]
            var n2 = other[i]
            if n1 > n2:
                return True
            elif n2 > n1:
                return False
        return False

    fn __le__(self, other: BigInt) -> Bool:
        return self < other or self == other

    fn __ge__(self, other: BigInt) -> Bool:
        return self > other or self == other

    fn __ne__(self, other: BigInt) -> Bool:
        return not self == other

    fn neg(mut self):
        self.sign = not self.sign

    fn __neg__(self) -> Self:
        var out = self
        out.neg()
        return out

    fn __bool__(self) -> Bool:
        return BigInt(0) != self

    # TODO
    # fn __invert__(self) -> Self:
    #     var out = self
    #     for i in range(out.size):
    #         out.store(i, abs(~out.load(i)))
    #     out.neg()
    #     return out
