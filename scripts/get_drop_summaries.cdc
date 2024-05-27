import "DropTypes"

access(all) fun main(contractAddress: Address, contractName: String, minter: Address?, quantity: Int?, paymentIdentifier: String?): [DropTypes.DropSummary] {
    return DropTypes.getAllDropSummaries(contractAddress: contractAddress, contractName: contractName, minter: minter, quantity: quantity, paymentIdentifier: paymentIdentifier)
}