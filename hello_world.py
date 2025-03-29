from genlayer import *

@gl.contract
class MyContract:
    variable: str = gl.public_state()
    def __init__(self):
        super().__init__()  # first we have initialize the code properly
        self.variable = "hello"  # then initialize the state setting
    @gl.view
    def read_method(self) -> str:
        return self.variable
    @gl.write
    def write_method(self, new_value: str) -> None:
        self.variable = new_value  # now use the passed value
