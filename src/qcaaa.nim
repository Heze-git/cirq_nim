import cirq_nim, random, sequtils, math, strutils, algorithm, sets
from std/times import getTime, toUnix, nanosecond

# This file will show how to do the Quantum computing an applied approch examples from the book

# 7.3 pg 85 Quantum Teleportation Example
#[
Gist: Send Q(|Q>) to Reciver securly
Sender: EPR pair A B (H A, CNOT A B)
Send B to reciever
Sender: Bell Measure (CNOT Q A, H Q, Measure Q A) -> gives two classical bits
Send classical bits to Reciver
Reciever:
|Classical bits | Operation on B |
| 00            | I              |
| 01            | Z              |
| 10            | X              |
| 11            | XZ             | # Z first then X

After this they will share the same state Q and B, |Q> = |B>
[qq] + [cc] > [q]
[qq]: EPR pair
[cc]: classical bits
[q]: state we wished to transmit
]#
let now = getTime()
randomize(now.toUnix * 1_000_000 + now.nanosecond) # Seeding the random generator
var circuit = initcirq()
# Quantum Teleportation template
template quantumTeleport(circuit: typed, a, b, q:untyped, random: typed): untyped =
  Circuit circuit:
    qubit a
    qubit b
    qubit q
    H a
    CNOT a b
    # Randomize the message |q> qubit q
    X q random
    Y q random
    # Send b
    CNOT q a
    H q
    Measure q
    Measure a
    # recover origal |q> form the state table above which is a CNOT and CZ min(I) max(XZ)
    CNOT a b
    CZ q b
    # Randomize the state of |q> again
    X q random
    Y q random

let randomamt:float = rand(1.0)
quantumTeleport(circuit, A, B, Q, randomamt)
#echo circuit.cirq_printCircuit()
#echo circuit.cirq_BlochResults("Q", "B") # The signs of Q and B can be diffrent which is something I don't understand
circuit.cirq_clearCircuit()

# Super Dense Coding pg 86-> Transfer multiple bits of classical information within a single (or less than the # of classical bits) qubit
#[Gist:
Sender: prepare EPR pair (A, B) -> H(A), CNOT(A, B)
Sender: Depedending on state desired to transmit work on the half of EPR pair(a)
| 00  | I  |
| 01  | X  |
| 10  | Z  |
| 11  | ZX | -> This translates to a CNOT and CZ
Sender sends b to Reciver
Recieve:
H(a)
Cnot(a, b)
Measure a b
[q] + [qq] >= [cc]
]#
template superDenseCoding(circuit: typed, a, b, c: untyped, binary: uint8): untyped =
  Circuit circuit:
    qubit a
    qubit b # He uses a line qubit 1-2
    H a
    CNOT a b
  # Depending on the input binary uint8 we preform diffrent operations on a
  if binary == 0b00:
    # Preform Idenity
    discard
  elif binary == 0b01:
    Circuit circuit:
      X a
  elif binary == 0b10:
    Circuit circuit:
      Z a
  elif binary == 0b11:
    Circuit circuit:
      X a
      Z a
  # Send b to reciver
  Circuit circuit: # Bell Measure
    CNOT a b
    H a
    Measure a
    Measure b

superDenseCoding(circuit, A, B, C, 0b01)
#echo circuit.cirq_printCircuit()
#echo circuit.cirq_simulateResults(1)
circuit.cirq_clearCircuit()

# Bell Inequality -> pg 88
#[
Gist: 2 players 1 ref the two players are seperated
loop round:
  Ref sends 1 bit (x) to plyr1, then depending on x plyr1 sends a(x) back to ref
  Ref sends 1 bit (y) to plyr2, then depending on y plyr2 sends b(y) bach to ref
  Ref decides winner based on:
    a(x) XOR b(y) == xy
|XOR table|Result |
|0 XOR 0  |0      |
|0 XOR 1  |1      |
|1 XOR 0  |1      |
|1 XOR 1  |0      |
plyr1and2 want to win as many rounds as possible
They can meet before to make a stategy this is a 2^4 (x, y, a(x), b(y)) binary table of strats
The best possible classical strategy can get a max of 75% win precentage chance \
in the quantum strategy they are allowed an entanglement resource, giving a winning possiblity of cos^2(pi/8) or 85%
Strategy:
 4 qubits (a, b, c, d)
 EPR pair (a, c)
 Random qubit is "sent" to plyr1 and plyr2 done by preforming H on b and d (to produce superposition)
 Then plyr1and2 preform CNOT -0.5 on thier qubits with the recieved b and d respectively
 Measure to record results
]#
template bellinequality(circuit: typed, a, b, c, d: untyped): untyped =
  Circuit circuit:
    qubit a
    qubit b
    qubit c
    qubit d
    # Prepare EPR pair of a and c then preform a -.25 X on a
    H a
    CNOT a c
    X a -0.25
    # Referree prepares randomized bits
    H b
    H d
    # Preform controled -sqrtX on qubits
    CNOT b a 0.5
    CNOT d c 0.5
    Measure a
    Measure b
    Measure c
    Measure d
#[
bellinequality(circuit, Alice, Ref1, Bob, Ref2)
# Calculate the winning precentage
echo circuit.cirq_printCircuit()
discard circuit.cirq_simulateResults(1000) # number of repetitions
let alice: string = circuit.cirq_targetResults("Alice")
let bob: string = circuit.cirq_targetResults("Bob")
let ref1: string = circuit.cirq_targetResults("Ref1")
let ref2: string = circuit.cirq_targetResults("Ref2")
var winprecentage: float = 0;
#for x in zip(alice, bob, ref1, ref2):
for x in 0..<len(alice):
  # These are overdone casts but whatever I could just have one if statement
  let a = (if int(alice[x]) - int('0') == 1: true else: false)
  let b = (if int(bob[x]) - int('0') == 1: true else: false)
  let c = (if int(ref1[x]) - int('0') == 1: true else: false)
  let d = (if int(ref2[x]) - int('0') == 1: true else: false)
  # For the long results
  # echo("a(x)b(y):" & (if a: "1" else: "0") & (if b:"1" else:"0") & " xy:" & (if c:"1" else: "0") & (if d: "1" else: "0") & " a(x)XORb(y) == xandy: " & (if ((a xor b) == (c and d)): "1" else: "0"))
  if (a xor b) == (c and d):
    winprecentage = winprecentage + 1
winprecentage = (winprecentage * 100) / 1000 # This / <number> is the # of repetitions
echo winprecentage
circuit.cirq_clearCircuit()
]#
# Start of the Canon
# Deutsh-Jozsa Algorithm
#[
Gist: f{0, 1} -> {0, 1}
Function takes 1bit input and gives one bit output, the function itself may be solving a complicated problem
but as it is 1-bit -> 1-bit there are 4 "types" the function can take
|x|f1|f0|fx|f!x|
|0| 1| 0| 0|  1|
|1| 1| 0| 1|  0|
Question: With the minimal number of quieries determine if f is constant or balanced (constant is f1, f0 and balanced is fx, f!x)
In a classical computer you would have to query at least twice to detmined 0 and 1 outputs
In a quantum computer you only need 1 query with a 1-bit boolean oracle (oracle is the constructed other-function that allows to determine the relationship of inputs to outputs for a black-box complicated function like f)
We need to make the computation reversable and in a classical approach it need not be so in worst case checking 2^n-1 + 1 or half to determine constant and best case the first two bits are diffrent
We can express this transformation as follows pg. 98 (with unary fucntion working on n+1 bits U_f)
U_f(|x>|y>):=|x>|y xor f(x)>
|x> computational basis states
|y> output qubit
The idea of the algorithm is to measure in a computational basis outside of z |0> and |1> (as we would gain no advantage), we measure in the Hadamard basis superposition
Circuit:
      n
|0> --/---[H^xor(n)]----[x[               ]x]----[H^xor(n)]---[M]
                        |        U_f        |
|1> ------[H]-----------[y[      ]y xor f(x)]--------------------

Transforms: |xy> -> |x(y xor f0)>
f0:[I]
|00> -> |00>
|01> -> |01>
|10> -> |10>
|11> -> |11>
f1:[X y]
|00> -> |01>
|01> -> |00>
|10> -> |11>
|11> -> |10>
fx:[CNOT x y]
|00> -> |00>
|01> -> |01>
|10> -> |11>
|11> -> |10>
f!x:[CNOT x y, X y] # 'inverse' of a CNOT
|00> -> |01>
|01> -> |00>
|10> -> |10>
|11> -> |11>
]#
# Define the oriacles functions
template fun0(circuit: typed, x, y: untyped):untyped =
  discard

template fun1(circuit: typed, x, y: untyped):untyped =
  Circuit circuit:
    X y

template funx(circuit: typed, x, y: untyped):untyped =
  Circuit circuit:
    CNOT x y

template funnotx(circuit: typed, x, y: untyped):untyped =
  Circuit circuit:
    CNOT x y
    X y
# To use quantum computing to solve in once query prepare y as |-> = (1/Sqrt(2))(|0> - |1>)
#[ Solving in U_f we get (pg.100) phase kickback to encode the information in the phase
U_f|x>|-> = (-1)^f(x)|x>|->
f0:[I]
(-1)^0|x>|-> ->
|00> => 1*|0>|->
|01> => 1*|0>|->
|10> => 1*|1>|->
|11> => 1*|1>|->
U_f|x>|-> = (-1)^f(x)|x>|->
f1:[-I]
|00> => -1*|0>|->
|01> => -1*|0>|->
|10> => -1*|1>|->
|11> => -1*|1>|->
U_f|x>|-> = (-1)^f(x)|x>|->
fx:[Z]
|00> =>  1*|0>|->
|01> =>  1*|0>|->
|10> => -1*|1>|->
|11> => -1*|1>|->
# The possible flip here is a Z operation
U_f|x>|-> = (-1)^f(x)|x>|->
f!x:[-Z]
|00> => -1*|0>|->
|01> => -1*|0>|->
|10> =>  1*|1>|->
|11> =>  1*|1>|->

To distingish between I and Z recall:
HZH = X
H = 1/srqt(2)*[1  1]
              [1 -1]
]#
# Now lets do 1bit => 1bit Deutsh-Jozsa
template onebitDeutch(circuit: typed, functName: typed, x, y: untyped):untyped =
  Circuit circuit:
    qubit x
    qubit y
    X y
    H x
    H y
    # Black box function
  functName(circuit, x, y)
    # Endo of BBF
  Circuit circuit:
    H x
    Measure x

    # Constant fucntions whould be proportional to I and give 0's
    # The balanced fucntions should be propotional to X and give 1's
onebitDeutch(circuit, fun0, X, Y)
#echo circuit.cirq_simulateResults(10)
circuit.cirq_clearCircuit()
onebitDeutch(circuit, fun1, X, Y)
#echo circuit.cirq_simulateResults(10)
circuit.cirq_clearCircuit()
onebitDeutch(circuit, funx, X, Y)
#echo circuit.cirq_simulateResults(10)
circuit.cirq_clearCircuit()
onebitDeutch(circuit, funnotx, X, Y)
#echo circuit.cirq_simulateResults(10)
circuit.cirq_clearCircuit()

# Now N-bit Deutsh-Jozsa is page 103
# These are n=2 I could make them like the function above but I will move onto The Bernstien-Vazirani Algorithm


# Bernstein-Vazirani Algorithm (Blackbox algorithm) pg.104
# First algorithm to show clear seperation between classical and quantum advantage even allowing small error
# This will make me make the line qubit operation
# Line and grid qubits are now supported
#[
Gist:
Given a function of N inputs f(xn-1..x0)
let a be an unknown non-negitive int less than 2^n
let f(x) take any integer x and mod 2 (sum x * a) st output=
  a * x = a0*x0 xor a1*x1 xor a2*x2 xor ...
Try to find a in one query
qubits:
  data-reg set to |0>, n
  target set to |1>, 1


]#

let qubitcount:int = 8
let samplecount:int = 3
var inputqubits: seq[string]
for i in 0..<qubitcount:
  let name: string = "q" & $i & "x0"
  inputqubits.add(name)
let outputqubit: string = "q8x0"
Circuit circuit:
  grid q qubitcount 0



# The output is q8x0, other are q7..0x0
let secretbiasbit:int = rand(1)
var secretFactorBits: seq[int]
for i in 0..<qubitcount:
  secretFactorBits.add(rand(1))

#[ Write the secret string
stdout.write("Secrete Function:\n f(x) = x*<")
for i in secretFactorBits:
  stdout.write($i)
stdout.write("> + " & $secretbiasbit & " (mod 2)\n")
]#



proc makeOracle(inputq: seq[string], outputq: string, secretFactor: seq[int], secretBias: int) =
  if secretBias == 1:
    Circuit circuit:
      X `outputq`
  for (qubit, bit) in zip(inputq, secretFactorBits):
    if bit == 1:
      Circuit circuit:
        CNOT `qubit` `outputq`


proc bernsteinVazirani(inputq: seq[string], outputq: string, function: proc(inputq: seq[string], outputq: string, secretFactor: seq[int], secretBias: int): void) =
  Circuit circuit:
    X `outputq`
    H `outputq`
  for x in inputq:
    Circuit circuit:
      H `x`
  function(inputq, outputq, secretFactorBits, secretbiasbit)
  for x in inputq:
    Circuit circuit:
      H `x`
  for x in inputq:
    Circuit circuit:
      Measure `x`

bernsteinVazirani(inputqubits, outputqubit, makeOracle)
#echo circuit.cirq_printCircuit()
#echo circuit.cirq_simulateResults(samplecount)
circuit.cirq_clearCircuit()


# Moving onto Simon's Problem
# Assuming that we have a 2:1 mapped function ie no inputs map to difrrent results but some inputs may map to the same output (specifically in a 2:1 ratio) we want to determine periodicity of this function f(x)[2:1]
#[
Consider an orcale that maps n-bit strings to m-bit strings s.t.
f:{0,1}^n -> {0,1}^m
m >= n
f[1:1] || f[2:1]
s ∈ {0, 1}^n # a non-zero period s.t. forall x, x0 we have f(x) = f(x0) iff x0 = x xor s
Goal:
determine if f is [1:1] or [2:1] and if it is [2:1] determine the period of f
EX:{https://en.wikipedia.org/wiki/Simon%27s_problem, https://github.com/quantumlib/Cirq/blob/master/examples/simon_algorithm.py, https://qiskit.org/textbook/ch-algorithms/simon.html}
Brute force the soltion in this example, to show how it works
n = 3
[<2:1pairs>]
x	  f(x)   f(s xor x)           other f(x0)  brute(s), s != 0^n
000	101[0] f(s xor 000) = 101 = f(110)       110
001	010[1] f(s xor 001) = 010 = f(111)       110
010	000[2] f(s xor 010) = 000 = f(100)       110
011	110[3] f(s xor 011) = 110 = f(101)       110
100	000[2] f(x xor 100) = 000 = f(010)       110
101	110[3] f(x xor 101) = 110 = f(011)       110
110	101[0] f(x xor 110) = 101 = f(000)       110
111	010[1] f(x xor 111) = 010 = f(001)       110 -> this brute force method takes 8 checks or 2^n checks to detrmine s positivitly
On average because this function may have n bits we first have to determien if its [2:1] or [1:1] which means cheacking at least half of the inputs output paits 2^n-1 + 1 checks
With better approach we can get classical rt of 2^n/2 (From the birthday paradox)
Once we find two inputs with same output we can x xor y = s to solve for s
s = 110, if s = 000 its onetoone
in a quantum computer we can solve this problem in O(n) orcale checks
This can be solved with simons circuit as follows:

      n
|0>---/---[H^(xor n)]--[|x>|y>              ]----[H^(xor n)]---[M]--
                       |  U                 |
      n                |   f                |
|0>---/----------------[     |x>|y xor f(x)>]---[M]--{f(z)}---------

U_f more explained:

              in                    out
|x>^n--------[[|x>]               [|x>]]------
             |       U_f               |
             |                         |
|y>^n--------[[|y>]      [|y xor f(x)>]]------

This means that |ψ> functions occur in these stages:
|ψ_1>: Prepare: |0>^n|0>^n
      n
|0>---/---

      n
|0>---/---

|ψ_2>: Hadamard The first |0>^n states = H^(xor n)|0>^n|0>^n

      n
|0>---/---[H^(xor n)]

      n
|0>---/--------------

|ψ_3>: here |y> = |0> so |y xor f(x)> = |f(x)> =>

1/sqrt(2^n)(n in {0,1})Sum|x>|f(x)>

      n
|0>---/---[H^(xor n)]--[|x>|y>              ]--
                       |  U                 |
      n                |   f                |
|0>---/----------------[     |x>|y xor f(x)>]--

(The inputs and corresponding outputs of f(x))

|ψ_4>: Measure the second reg to remove it from superposition
      n
|0>---/---[H^(xor n)]--[|x>|y>              ]------
                       |  U                 |
      n                |   f                |
|0>---/----------------[     |x>|y xor f(x)>]---[M]

(1st reg should have superpostion of inputs that can produce f(z)) [2:1]
=>
((|z>+|z xor s>)/(sqrt(2)))|f(z)>
|ψ_5>: H^((x) n)|x>|f(z)> =

((1)/(sqrt(2^n))((1)/(sqrt(2)))*((y in {0,1}^n)sum(-1^(y . z)|y> + sum(-1^(y . (z xor s)|y>))))|f(z)>

=>

((1)/(sqrt(2^n=1)))((y in {0, 1}^n)sum(-1)^(y . z)(1 + -1^(y . z))|y>)
2 cases from here:
prob of y . s == 1: 0%
prob of y . s == 0: 100% -> collect n-1 lineraly independant values of y. Then use Linear algerbra to solve y . s for s
      n
|0>---/---[H^(xor n)]--[|x>|y>              ]----[H^(xor n)]-
                       |  U                 |
      n                |   f                |
|0>---/----------------[     |x>|y xor f(x)>]---[M]--{f(z)}--



]#

# Lets implement this for n = 3
let newnow = getTime()
randomize(newnow.toUnix * 1_000_000 + newnow.nanosecond) #another randomize
########################################################
#-----------------NSIZE--------------------------------#
let nsize:int = 3 # there are 2^n possible inputs-----#
#------------------------------------------------------#
########################################################
var secretString: seq[int]
for i in 0..<nsize:
  secretString.add(rand(1))

stdout.write("Simon's Secret String: ")
for i in secretString:
  stdout.write(i)
echo ""
# Make the line of nsize qubits
let fullline = 2*nsize - 1 # 5, if n = 2 2*2-1 3: 0 1 2 3
Circuit circuit:
  line lineof fullline # Makes top0..2*nsize, inputs[top0,top1,top2], ouputs[top3,top4,top5]   # top6 Junk

var inputtedqubits: seq[string] # lineof0..nsize-1
var outputtedqubits: seq[string] # lineofnsize+1..nsize*2
for i in 0..<nsize: # 0 1 2
  let addqbit:string = "lineof" & $i
  inputtedqubits.add(addqbit)
for i in nsize..fullline: # 3 4 5
  let addqbit:string = "lineof" & $i
  outputtedqubits.add(addqbit)

proc simonOracle(inputqubits: seq[string], outputqubits: seq[string], secretString: seq[int]): void =
  # "copy"
  for (controlbit, targetbit) in zip(inputqubits, outputqubits):
    Circuit circuit:
      CNOT `controlbit` `targetbit`
  # if s is not 0^n, on each s_i != 0, XOR copyx_i with s 
  if sum(secretString) != 0: # for sum(s) == 0 it is trival
    # not 1-to-1
    # For all the matching secret bits add a new CNOT corresponding to the input output pair |a xor f(x)>
    #[ OLD and WRONG:
    var position: int = 0
    for bit in secretString:
      let input: string = "lineof" & $position
      if bit == 1:
        for i in nsize..fullline:
          let output: string = "lineof" & $i
          Circuit circuit:
            CNOT `input` `output`
      position = position + 1
     ]#
    # this is dumb but I don't want ot go through nims standard libarary rn looking for this feature
    var position: int = 0
    var leftmost: int = 0
    for bit in secretString:
      # these will be reversed 110 [1][0],[1][1],[0][2]
      # it is always the least signifigant that gets CNOT'd
      if bit == 1:
        leftmost = position
      position = position + 1 # find the least signifigant position (leftmost)
    # leftmost is now the gate we will be CNOT'ing on for each position gate of 1 in s
    position = 0
    let input: string = "lineof" & $(nsize - leftmost - 1)
    position = fullline
    for i in secretString:
      let output:string = "lineof" & $position
      if i == 1:
        Circuit circuit:
          CNOT `input` `output`
      position = position - 1

proc makeSimonCircuit(inputqubits: seq[string], outputqubits: seq[string], oracle: proc(p1: seq[string], p2: seq[string], p3: seq[int]): void): void =
  # Prepare the inputs psi 1
  for i in inputqubits:
    Circuit circuit:
      H `i`
  # psi 2 ^^^
  oracle(inputqubits, outputqubits, secretString)
  # psi 3 ^^^
  
  for i in outputqubits:
    Circuit circuit:
      Measure `i`
  
  # psi 4 ^^^
  for i in inputqubits:
    Circuit circuit:
      H `i`
      Measure `i`
  # psi 5 ^^^

let simulate_amt:int = 10
makeSimonCircuit(inputtedqubits, outputtedqubits, simonOracle)
echo circuit.cirq_printCircuit()
discard circuit.cirq_simulateResults(simulate_amt)
var simonresults: seq[string]
for i in 0..<nsize:
  # For each i in nsize sum the 1's and 0's and see which was more common then return the predicible s string
  # Solve the system of linear equations
  # s.results = 0 mod 2
  simonresults.add(circuit.cirq_targetResults("lineof" & $i))
var buildresults: seq[string]
var stringofstring:string # man im lazy
for i in 0..<simulate_amt:
  for j in 0..<nsize:
    if simonresults[j][i] != '\n':
      stringofstring = stringofstring & simonresults[j][i]

var counter: int = 0
var build: string = ""
for i in 0..stringofstring.len-1:
  build = stringofstring[i] & build
  if counter == nsize - 1:
    buildresults.add(build)
    build = ""
    counter = 0
  else:
    counter = counter + 1

proc bdotz(b: seq[int], z: string): int =  
  var accum: int = 0
  for (x, y) in zip(b, z):
    if y != '\n':
      accum = accum + x * parseInt($y)
  result = (accum mod 2)

echo "sequence of Gaussian matrixes to solve back to s: "
var buildresultsset: HashSet[string] = toSet(buildresults)
for x in buildresultsset:
  echo $secretString & "." & $x & " = " & $bdotz(secretString, x) & " (mod 2)"
circuit.cirq_clearCircuit()







