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
    minterPrivatePath: PrivatePath,
    nftTypeIdentifier: String
) {
    prepare(acct: AuthAccount) {
        if acct.borrow<&AnyResource>(from: FlowtyDrops.ContainerStoragePath) == nil {
            acct.save(<- FlowtyDrops.createContainer(), to: FlowtyDrops.ContainerStoragePath)

            acct.unlink(FlowtyDrops.ContainerPublicPath)
            acct.link<&{FlowtyDrops.ContainerPublic}>(FlowtyDrops.ContainerPublicPath, target: FlowtyDrops.ContainerStoragePath)
        }

        let minter = acct.getCapability<&{FlowtyDrops.Minter}>(minterPrivatePath)
        assert(minter.check(), message: "minter capability is not valid")

        let container = acct.borrow<&FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
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
