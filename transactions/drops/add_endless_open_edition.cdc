import "FlowtyDrops"
import "DropFactory"

import "MetadataViews"

transaction(
    name: String,
    description: String,
    ipfsCid: String,
    ipfsPath: String?,
    price: UFix64,
    paymentIdentifier: String,
    minterControllerID: UInt64,
    nftTypeIdentifier: String
) {
    prepare(acct: auth(Storage, Capabilities) &Account) {
        if acct.storage.borrow<&AnyResource>(from: FlowtyDrops.ContainerStoragePath) == nil {
            acct.storage.save(<- FlowtyDrops.createContainer(), to: FlowtyDrops.ContainerStoragePath)

            acct.capabilities.unpublish(FlowtyDrops.ContainerPublicPath)
            acct.capabilities.publish(
                acct.capabilities.storage.issue<&{FlowtyDrops.ContainerPublic}>(FlowtyDrops.ContainerStoragePath),
                at: FlowtyDrops.ContainerPublicPath
            )
        }

        let controller = acct.capabilities.storage.getController(byCapabilityID: minterControllerID)
            ?? panic("minter capability not found")

        let minter = controller.capability as! Capability<&{FlowtyDrops.Minter}> 
        assert(minter.check(), message: "minter capability is not valid")

        let container = acct.storage.borrow<auth(FlowtyDrops.Owner) &FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
            ?? panic("drops container not found")

        let paymentType = CompositeType(paymentIdentifier) ?? panic("invalid payment identifier")

        let dropDisplay = MetadataViews.Display(
            name: name,
            description: description,
            thumbnail: MetadataViews.IPFSFile(cid: ipfsCid, path: ipfsPath)
        )
        let drop <- DropFactory.createEndlessOpenEditionDrop(price: 1.0, paymentTokenType: paymentType, dropDisplay: dropDisplay, minterCap: minter, nftTypeIdentifier: nftTypeIdentifier)
        container.addDrop(<- drop)
    }
}
