import "DropTypes"

pub fun main(contractAddress: Address, contractName: String, minter: Address?): [DropTypes.DropSummary] {
    return DropTypes.getAllDropSummaries(contractAddress: contractAddress, contractName: contractName, minter: minter)
}