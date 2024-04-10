import "DropTypes"

pub fun main(contractAddress: Address, contractName: String, dropID: UInt64, minter: Address?): DropTypes.DropSummary? {
    return DropTypes.getDropSummary(contractAddress: contractAddress, contractName: contractName, dropID: dropID, minter: minter)
}