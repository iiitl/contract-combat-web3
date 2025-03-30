from genlayer import *
 
@gl.contract
class MyContract:

       variable: str
 
       def __init__(self):
           self.variable = "initial value"
 
       @gl.public.view
       def read_method(self) -> str:
           return self.variable
 
       @gl.public.write
       def write_method(self, new_value: str):
           self.variable = new_value