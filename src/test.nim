import cirq_nim

var circuit = initcirq()

# Help setting up the macro

Circuit circuit:
  qubit R
  qubit S
  qubit Q
  H R
  CNOT R S
  CNOT Q R
  H Q
  Measure R
  Measure Q
  qubit A
  qubit B
  SWAP A B
# The type of this macro exists already as it is a var circuit = initcirq()


echo circuit.cirq_simulateResults(1)
echo circuit.cirq_printCircuit()
