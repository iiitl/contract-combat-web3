from genlayer import *

@gl.contract
class MyContract:
    variable: gl.Storage[str]

    def __init__(self):
        gl.initialize(self)
        self.variable.set("hello")

    @gl.public.view
    def read_method(self) -> str:
        return self.variable.get()

    @gl.public.write
    def write_method(self, new_value: str) -> None:
        self.variable.set(new_value)
