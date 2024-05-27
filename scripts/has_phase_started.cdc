import "FlowtyDrops"
import "ViewResolver"

access(all) fun main(contractAddress: Address, contractName: String, dropID: UInt64, phaseIndex: Int): Bool {
    let resolver = getAccount(contractAddress).contracts.borrow<&{ViewResolver}>(name: contractName)
        ?? panic("contract does not implement ViewResolver interface")

    let dropResolver = resolver.resolveContractView(resourceType: nil, viewType: Type<FlowtyDrops.DropResolver>())! as! FlowtyDrops.DropResolver

    let container = dropResolver.borrowContainer()
        ?? panic("drop container not found")

    let drop = container.borrowDropPublic(id: dropID)
        ?? panic("drop not found")

    let phase = drop.borrowPhasePublic(index: phaseIndex)

    return phase.getDetails().switcher.hasStarted()
}