import "FlowtyDrops"
import "ViewResolver"

access(all) fun main(contractAddress: Address, contractName: String, dropID: UInt64, phaseIndex: Int, minter: Address, numToMint: Int, totalMinted: Int, paymentIdentifier: String): Bool {
    let paymentTokenType = CompositeType(paymentIdentifier)!

    let resolver = getAccount(contractAddress).contracts.borrow<&{ViewResolver}>(name: contractName)
        ?? panic("contract does not implement ViewResolver interface")

    let dropResolver = resolver.resolveContractView(resourceType: nil, viewType: Type<FlowtyDrops.DropResolver>())! as! FlowtyDrops.DropResolver

    let container = dropResolver.borrowContainer()
        ?? panic("drop container not found")

    let drop = container.borrowDropPublic(id: dropID)
        ?? panic("drop not found")

    let phase = drop.borrowPhasePublic(index: phaseIndex)
    return phase.getDetails().addressVerifier.canMint(addr: minter, num: numToMint, totalMinted: totalMinted, data: {})
}