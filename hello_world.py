from genlayer import *

@gl.contract
class MyContract:
    variable: str

    def __init__(self):
        self.variable = "Ranjni beats Tanmay"

    @gl.public.view
    def read_method(self) -> str:
        return self.variable

    @gl.public.write
    def write_method(self,new_value:str) -> None:
        self.variable = "Tanmay Died"
