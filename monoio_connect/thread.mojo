from .pthread import pthread_create
from .log import loge


alias ThreadTaskFn = fn (context: UnsafePointer[UInt8]) -> UInt8


alias TaskFn = fn () raises -> None


fn __do_task(context: UnsafePointer[UInt8]) -> UInt8:
    var task = context.bitcast[TaskFn]()
    try:
        task[]()
    except err:
        loge("Task failed: " + str(err))
    task.free()
    return 0


fn start_thread(task: TaskFn) raises -> UInt64:
    """Create and start a new thread with the given task function.

    Args:
        task: The function to run in the new thread.

    Returns:
        Thread ID if successful.

    Raises:
        Error if thread creation fails.
    """
    var p = UnsafePointer[TaskFn].alloc(1)
    __get_address_as_uninit_lvalue(p.address) = task
    var context = UnsafePointer[UInt8]()
    context = p.bitcast[UInt8]()
    return start_thread(__do_task, context)


struct ThreadContext[T: AnyType]:
    var task: fn (context: UnsafePointer[T]) raises -> None
    var data: UnsafePointer[T]

    fn __init__(
        out self,
        task: fn (context: UnsafePointer[T]) raises -> None,
        data: UnsafePointer[T],
    ):
        self.task = task
        self.data = data

    fn __call__(mut self) raises:
        self.task(self.data)

    fn free(owned self):
        self.data.free()


fn __do_task_with_context[T: AnyType](context: UnsafePointer[UInt8]) -> UInt8:
    var thread_context = context.bitcast[ThreadContext[T]]()
    try:
        thread_context[]()
    except err:
        loge("Task failed: " + str(err))
    thread_context.free()
    return 0


fn start_thread[
    T: AnyType
](
    task: fn (context: UnsafePointer[T]) raises -> None, data: UnsafePointer[T]
) raises -> UInt64:
    """Create and start a new thread with the given task function.

    Args:
        task: The function to run in the new thread.
        data: Pointer to thread context data.

    Returns:
        Thread ID if successful.

    Raises:
        Error if thread creation fails.
    """
    var p = UnsafePointer[ThreadContext[T]].alloc(1)
    __get_address_as_uninit_lvalue(p.address) = ThreadContext[T](task, data)
    var context = UnsafePointer[UInt8]()
    context = p.bitcast[UInt8]()
    return start_thread(__do_task_with_context[T], context)


fn start_thread(
    task: ThreadTaskFn, mut context: UnsafePointer[UInt8]
) raises -> UInt64:
    """Create and start a new thread with the given task function and context.

    Args:
        task: The function to run in the new thread.
        context: Pointer to thread context data.

    Returns:
        Thread ID if successful.

    Raises:
        Error if thread creation fails.
    """
    var thread_id: UInt64 = 0
    if pthread_create(thread_id, task, context) != 0:
        raise Error("Failed to create thread")
    return thread_id
