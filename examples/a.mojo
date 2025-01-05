# print
def main():
    print("hello world")


# create variable (not learned types yet)
def main2():
    a = "hello world"
    b = 1
    print(a, b)


# print trough function
def printer(a):
    print(a)


def main3():
    a = "hello world"
    printer(a)


# modify variables
def add_one(mut a: Int):
    a += 1


def main4():
    a = 0
    add_one(a)
    print(a)


# here there is another gradual step (currently worked on)
# (create auto dereferenced reference and not learned lifetime yet)


# create safe reference (not learned lifetime yet)
def main5():
    a = 0
    b = Pointer.address_of(a)
    a += 1
    print(b[])


# return auto dereference (not learned lifetime yet)
def return_ref(arg: List[Int]) -> ref [arg] List[Int]:
    return arg


def main6():
    a = List(1, 2, 3)
    a.append(4)
    print(return_ref(a)[3])


# return mutable auto dereference (not learned lifetime yet)
def return_mut_ref(mut arg: List[Int]) -> ref [arg] List[Int]:
    return arg


def main7():
    a = List(1, 2, 3)
    return_mut_ref(a).append(4)
    print(len(a))


# return inferred mutability auto dereference (not learned lifetime yet)
def return_inferred_mut_ref(ref [_]arg: List[Int]) -> ref [arg] List[Int]:
    return arg


def main8():
    a = List(1, 2, 3)
    return_mut_ref(a).append(4)
    print(len(a))


# return immutable auto dereference
def return_immutable_ref[
    L: ImmutableOrigin
](ref [L]arg: List[Int]) -> ref [L] List[Int]:
    return arg


def main9():
    a = List(1, 2, 3)
    a.append(4)
    print(return_immutable_ref(a)[4])
    print(len(a))


# return mutable reference
def return_mutable_ref2[
    L: MutableOrigin
](ref [L]arg: List[Int]) -> Pointer[List[Int], L]:
    return Pointer.address_of(arg)


def main10():
    a = List(1, 2, 3)
    b = return_mutable_ref2(a)
    c = b
    c[].append(4)
    print(len(a))
