# Goal of this program is to provide functions and types (in the future probabably macros (ver 2)) for generating and calling python cirq code
# If this is successful I will look into directly calling these things without the middle-man of python if possible (ver 3)
# Then returning that code in a future type of Nim
#[
* Author: Hezekiah Gabaldon
* Version: 0.1.0 --> maybe I should update this
* Nim-Ver: 1.6.0
* this is all nimble file stuff you know where to find it.
]#
# I want to make more compile time failures as currently runtime catches if you don't use the macro system
# Imports
# Pure
import strutils, osproc, macros, os
# Impure
#import re
# not having access to the Forigen Function interface means I cannot make this {.compileTime.} pragma-able I will have to use a pure work around
# let patternNum = re"\d+.*" # Any digit start followed by any number of other characters

# Type definition for this code, I wanted to do a macro but for PoC I will use a type here and mess with the AST later
# The instruction type should only be modifiable through the functions provided in this module and username and password are set on instatiation
type
  cirq_conn* = object
    # have to make the sequence a refrence if i want to do multiple object pass (future concern)
    inst: seq[string] # sequence of instructions to be called
    opts: seq[string] # this is the completed opt string from the opts
    qubits: seq[string] # sequence of active qubits
    # resultant: string # the result value of operations get stored here
    resultant: string 
    # Possible fields: password, username, connect_info, compile target (qiskit)

# getter for resultant
proc cirq_getResultant(cirq_q: var cirq_conn): string = 
  result = cirq_q.resultant
# Constructor for the circuit
proc initcirq*(): cirq_conn {.compileTime.}=
  result.inst = @[]
  result.opts = @[]
  result.qubits = @[]
  result.resultant = ""
# These are the custom exception types
#[type 
  moduleExceptions = ref object of Exception
    predefinedQubit:uint32
]#
# to address this non-public type they must use the public functions in this module
#var cirq_q: cirq_conn # This is the cirq_conn that the operations in the module will work on

# Void function which creates a qubit and adds it to the qubit and inst list
proc cirq_createQbit*(cirq_q: var cirq_conn, name: string) =
  if name in cirq_q.qubits:
    let problem = "The qubit was already set under the name: " & name
    raise newException(Exception,problem)
  if name.contains "_":
    let problem = "The qubit name cannot contain \"_\": " & name
    raise newException(Exception,problem)
  if name == "ops":
    let problem = "This word is reserved for the circuit creation: " & name
    raise newException(Exception, problem)
  #[ Need a new non-re way to address this 
  let invalid: int = find(name, patternNum)
  if not invalid == -1:
    let problem = "This name cannot be used as it starts with a number: " & name
    raise newException(Exception, problem)
   
   if name[0] == 0, 1, 2, 3, 4, 5, 6, 7, 8, 9: fail else pass
  ]#
  # I hate this but for now it should be fine
  if $name[0] == "0" or $name[0] == "1" or $name[0] == "2" or $name[0] == "3" or $name[0] == "4" or $name[0] == "5" or $name[0] == "6" or $name[0] == "7" or $name[0] == "8" or $name[0] == "9":
    let problem = "This name cannot be used as it starts with a number: " & name
    raise newException(Exception, problem)
  cirq_q.qubits.add(name)
  # I also should check for invalid naming schemes like starting with a number
  # Using prefix checking during the python code generation, this may be reworked in the future as right now this is a proof of concept
  #let instruction: string = "CreateQubit_" & name
  #cirq_q.inst.add(instruction) # Might not what to create qubits here but instead create in the other qubitseq -> instseq
  # We will be using the named qubit function from cirq manuel to generate the qubits names and "tied" values
  # Currently these use absttracted names but they might need the BristleCone Architecture to be considered
# This currentl supports named qubits creation but cirq supports LineQubit(<num>) (x, y , z = LineQubit.range(3)) and GridQubit(<num>, <num>) (with specialties like GridQubit.square(<num>))
# Also there are prepackaged assortmants of qubits



# Prepare operation function on a qubit
# Hadamard
proc cirq_H*(cirq_q: var cirq_conn, name: string) =
  if name notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name
    raise newException(Exception, problem)
  let instruction: string = "HADAMARD_" & name
  cirq_q.inst.add(instruction)

# Not Function X operator
proc cirq_X*(cirq_q: var cirq_conn, name: string) =
  if name notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name
    raise newException(Exception, problem)
  let instruction: string = "NOT_" & name
  cirq_q.inst.add(instruction)

# The Y rotation pauli matrix 
proc cirq_Y*(cirq_q: var cirq_conn, name: string) =
  if name notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name
    raise newException(Exception, problem)
  #[
  Y-pauli operator roatates a state about the Y-axis EX on: |1> 
  (0 -i)(0) => (-i) or -i|0>
  (i  0)(1) => ( 0)
  ]#
  let instruction: string = "YROT_" & name
  cirq_q.inst.add(instruction)

# 
proc cirq_Z*(cirq_q: var cirq_conn, name: string) =
    if name notin cirq_q.qubits:
      let problem = "The qubit was not declaired: " & name
      raise newException(Exception, problem)
      #[
      Z-Pauli Operator rotates a state about the Z-axis EX on: |1>
2      (1  0) (0) -> ( 0)
      (0 -1) (1) -> (-1)
      ]#
    let instruction: string = "ZROT_" & name
    cirq_q.inst.add(instruction)

# Function to add a mesure to list of instruction
# I could make this take var args so we can save space setting up circuits
proc cirq_Measure*(cirq_q: var cirq_conn, name: string) =
  if name notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name
    raise newException(Exception, problem)
  let instruction: string = "MEASURE_" & name
  cirq_q.inst.add(instruction)

# CNOT Function takes two qubits 
proc cirq_CNOT*(cirq_q: var cirq_conn, name1, name2 :string) =
  if name1 notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name1
    raise newException(Exception, problem)
  if name2 notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name2
    raise newException(Exception, problem)
  let instruction: string = "CNOT_" & name1 & "_" & name2
  cirq_q.inst.add(instruction)

proc cirq_SWAP*(cirq_q: var cirq_conn, name1, name2: string) =
  if name1 notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name1
    raise newException(Exception, problem)
  let instruction: string = "SWAP_" & name1 & "_" & name2
  cirq_q.inst.add(instruction)

# Function to construct the operators
# I could make this a silent operation after the operators are updated 
proc cirq_constructopts(cirq_q: var cirq_conn) =
  cirq_q.opts.setLen(0) # clear the current opts
  if len(cirq_q.inst) == 0:
    let problem = "The instruction sequence is empty cannot construct a circuit"
    raise newException(Exception, problem)
  # Make a case statement running through the instructions
  for i in cirq_q.inst:
    # depending on which sintruction prefix I have to generate diffrent code
    let splited = i.split('_')
    case splited[0]
    of "NOT":
      cirq_q.opts.add("cirq.X(" & splited[1] & ")")
    of "HADAMARD":
      cirq_q.opts.add("cirq.H(" & splited[1] & ")")
    # Mesure criteria
    of "MEASURE":
      # cirq_q.opts.add("cirq.measure(" & splited[1] & ", key =\'m\')"
      cirq_q.opts.add("cirq.measure(" & splited[1] & ")")
    of "CNOT":
      cirq_q.opts.add("cirq.CNOT(" & splited[1] & "," & splited[2] & ")")
    of "YROT":
      cirq_q.opts.add("cirq.Y(" & splited[1] & ")")
    of "ZROT":
      cirq_q.opts.add("cirq.Z(" & splited[1] & ")") # still need to add the function for swap
    of "SWAP":
      cirq_q.opts.add("cirq.SWAP(" & splited[1] & "," & splited[2] & ")")
    else:
      discard # Nothing to do

# Function to cronstruct the call to python or rather the python code
proc cirq_constructPy(cirq_q: var cirq_conn): string  =
  # I could make this in a static block and have the calulation part of the compile process by offloading the calcs there 
  # Construct the opts
  cirq_constructopts(cirq_q)
 # Currently the code size is limited by string size there are whats around this but future me will address this -> I could make large files by breaking them into chunks
  # https://github.com/quantumlib/Cirq/issues/4637 -> importlib issue on python 3.10.0 
  var code: string = "from importlib import abc\nimport cirq\n" # starts with a import cirq statement
  var fillopt: string = "ops = ["
  # I was going to go out of my way and generate a name but thats for a later version
  for qubit in cirq_q.qubits:
    # Defines a list of qubit refrences 
    let refrence = qubit & " = " & "cirq.NamedQubit(\"" & qubit & "\")\n"
    # Expand the code generated
    code = code & refrence
  for opt in cirq_q.opts:
    fillopt.add(opt & ",")
  # Once this for loop ends we must close fillopt as it ends int
  try:
    fillopt.delete(len(fillopt)-1,len(fillopt))
  except:
    echo("Error encounterd with fillopt")
  fillopt.add("]\n") # close the ops expression
  code = code & fillopt
  # Generate the circuit as text
  # From opts has been depricated
  code = code & "circuit = cirq.Circuit(ops)\n"
  result = code 


proc cirq_printCircuit*(cirq_q: var cirq_conn): string =
  # Calls python3 -c <code>
  let call:string = "python -c \'" & cirq_constructPy(cirq_q) & "print(circuit)\n\'"
  let (results, _) = execCmdEx(call)
  result = results


# This exists becasue of https://github.com/nim-lang/Nim/issues/12516
# This will offload the results to a file named staticcirqnim.staticcirqnim, because to be frank I cannot really understand quite yet what implemenmtation they have gone with and am still working on this feature does const or var{.compileTime.} pass the threshold of RT CT who knows
# Mesuring Results static version
# This solution is jank and I want to update it sometime soon
# Built in write functions for single use ease is what these are rn
proc cirq_simulatestaticResults*(cirq_q: var cirq_conn, times: int): string =
  # First set up the instruction remember current instructions
  # I hate how this is done
  let call: string = "python -c \'" & cirq_constructPy(cirq_q) & "simulator = cirq.Simulator()\nresults=simulator.run(circuit,repetitions=" & $times & ")\nprint(results)\n\'"
  let results = staticExec(call) # this osproc calls also may include some issues for {.compileTime.}
                                 # This version changed: let (results, _) = execCmdEx(call) : to what it is today
  # if i use static exec to write to file i will lock out windows and Mac users and have to use building in cmds from those OS (as well as determine the os -> which i belive nim has built ins for at the runtime as well)
  #var file = open("staticcirqnim.staticcirqnim")
  #file.write(results)
  # Need to detect platform when using these but rn this is okay for testing
  discard staticExec("echo \"" & results & "\" > staticcirqnim.staticcirqnim")

  cirq_q.resultant = results
  result = results

proc cirq_getStaticResults*(): string =
  if not fileExists("staticcirqnim.staticcirqnim"):
    let problem = "The static circuit was never ran!"
    raise newException(Exception, problem)
  else:
    let contents = readFile("staticcirqnim.staticcirqnim")
    # kill the file just for neatness here, might remove this later, edit i did
    # removeFile("staticcirqnim.staticcirqnim")
    result = contents


proc cirq_simulateResults*(cirq_q: var cirq_conn, times: int): string =
  # First set up the instruction remember current instructions
  # I hate how this is done
  let call: string = "python -c \'" & cirq_constructPy(cirq_q) & "simulator = cirq.Simulator()\nresults=simulator.run(circuit,repetitions=" & $times & ")\nprint(results)\n\'"
  let (results, _) = execCmdEx(call) # this osproc calls also may include some issues for {.compileTime.} as importc is used and thats a FFI function which is not available at CT 
  cirq_q.resultant = results # Set resultant to recent results
  result = results


  # Want to var args this in the future as well but for now this function will extract results of a qubit name
proc cirq_targetResults*(cirq_q: var cirq_conn, name: string):string  = 
  if name notin cirq_q.qubits:
    let problem = "The qubit was not declaired: " & name
    raise newException(Exception, problem)
  # Extract the desired number results
      # let matchThis = re(name) # kinda costly
  let position: int = find(cirq_q.resultant, name)
  if position == -1:
    result = "Result not Found: " & name
  else:
    let largestring:string = cirq_q.resultant[position .. len(cirq_q.resultant)-1]
    let newlineposition:int = find(largestring, "\n")
    var line: string = largestring[0 .. newlineposition]
    let prefix:string = name & "="
    line.removePrefix(prefix)
    result = line

# Function to extract precompiled targeted results
proc cirq_extractResults*(fromresult, name: string):string  = 
  let position: int = find(fromresult, name)
  if position == -1:
    result = "Result not Found: " & name
  else:
    let largestring:string = fromresult[position .. len(fromresult)-1]
    let newlineposition:int = find(largestring, "\n")
    var line: string = largestring[0 .. newlineposition]
    let prefix:string = name & "="
    line.removePrefix(prefix)
    result = line

#  Clear object proc
proc cirq_clearCircuit*(cirq_q: var cirq_conn) =
  cirq_q.inst.setLen(0)
  cirq_q.qubits.setLen(0)
  # I don't clear the opts or the resultant as they are used and modified by other functions only



#[
I now want to write macros to make the syntax look better as a disguise for these functions
I also will work on intergrating the python to C to make it run faster and allow for static analysis of the code for offloading work to compile time.
python to C -- This is a bit of a pipe dream as I doubt there is a cython or other that exists for this but I might try to find or even make my own if possible
]#

#[
What do I want it to look like:
var circuit = initcirq()
Circuit circuit: # name of circuit
        qubit R
        qubit S
        qubit Q
        H R
        CNOT R S
        CNOT Q R
        H Q
        Measure Q
        Measure R
  -> decomposes to: circuit.cirq_createQbit("a") and so on
]#
# Macro system
macro Circuit*(typeName: typed, fieldsof: untyped): untyped =
  # Currently this marcos are for quickly desiging and setting up circuits there are not interiely complete or implemented so just as everythign here have fun feel freee to mess with it and use with caution
  result = newStmtList()
  for call in fieldsof:
    # Thesea are each instantces of calls
    # Figure out the function type to calls
    #echo $call[0] # the 'funct' or qubit or measure or whatever
    #echo $call[1] # The Second identifier
    #echo $call[2] # The thrid identifier
    # Macro creates a qubit
    if $call[0] == "qubit":
      # add a new qubit create call
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_createQbit")
        ),
       newStrLitNode($call[1])))
    # Hadamard gates
    elif $call[0] == "H":
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_H")
        ),
        newStrLitNode($call[1])
      ))
    # NOT GATES
    elif $call[0] == "X":
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_X")
        ),
        newStrLitNode($call[1])
      ))
    # Y rotation
    elif $call[0] == "Y":
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_Y")
        ),
        newStrLitNode($call[1])
      ))
    # 180 rotation Z 
    elif $call[0] == "Z":
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_Z")
        ),
        newStrLitNode($call[1])
      ))
    # Controllled nots
    elif $call[0] == "CNOT":
      # Then this is a nested command structure
      # The Second part is the "second call"
      #[
      Essentailly you can think of this as a sub seq of another seq
      for subcall in call[1]:
        listofCalls.add(subcall.strVal)
      ]#
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_CNOT")
        ),
        newStrLitNode($call[1][0].strVal),
        newStrLitNode($call[1][1].strVal)
      ))
    elif $call[0] == "SWAP":
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_SWAP")
        ),
        newStrLitNode($call[1][0].strVal),
        newStrLitNode($call[1][1].strVal)
      ))
    # Measure Gate
    elif $call[0] == "Measure":
      result.add(newCall(
        newDotExpr(
          newIdentNode(typeName.strVal),
          newIdentNode("cirq_Measure")
        ),
        newStrLitNode($call[1])
      ))



