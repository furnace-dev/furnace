from .base import Callbacks, SubOperation


trait Marketable:
    fn set_callbacks(self, callbacks: Callbacks) raises -> None:
        ...

    fn subscribe(self, subs: List[SubOperation]) raises -> None:
        ...

    fn run(self) raises -> None:
        ...

    fn close(self) raises -> None:
        ...