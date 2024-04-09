import "FlowtyDrops"
import "ViewResolver"

pub fun main(contractAddress: Address, contractName: String, dropID: UInt64): [UInt64] {
    let resolver = getAccount(contractAddress).contracts.borrow<&ViewResolver>(name: contractName)
        ?? panic("contract does not implement ViewResolver interface")

    let dropResolver = resolver.resolveView(Type<FlowtyDrops.DropResolver>())! as! FlowtyDrops.DropResolver

    let container = dropResolver.borrowContainer()
        ?? panic("drop container not found")

    let drop = container.borrowDropPublic(id: dropID)
        ?? panic("drop not found")

    let phases = drop.borrowActivePhases()
    let ids: [UInt64] = []
    for p in phases {
        ids.append(p.uuid)
    }

    return ids
}