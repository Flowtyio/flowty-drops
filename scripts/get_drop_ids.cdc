import "FlowtyDrops"
import "ViewResolver"

access(all) fun main(contractAddress: Address, contractName: String): [UInt64] {
    let resolver = getAccount(contractAddress).contracts.borrow<&{ViewResolver}>(name: contractName)
    if resolver == nil {
        return []
    }

    let tmp = resolver!.resolveContractView(resourceType: nil, viewType: Type<FlowtyDrops.DropResolver>())
    if tmp == nil {
        return []
    }

    let dropResolver = tmp! as! FlowtyDrops.DropResolver

    if let dropContainer = dropResolver.borrowContainer() {
        return dropContainer.getIDs()
    }

    return []
}