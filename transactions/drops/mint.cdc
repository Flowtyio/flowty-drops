import "ViewResolver"
import "MetadataViews"
import "NonFungibleToken"
import "FungibleToken"

import "FlowtyDrops"

transaction(
    contractAddress: Address,
    contractName: String,
    numToMint: Int,
    totalCost: UFix64,
    paymentIdentifier: String,
    paymentStoragePath: StoragePath,
    paymentReceiverPath: PublicPath,
    dropID: UInt64,
    dropPhaseIndex: Int,
    nftIdentifier: String,
    commissionAddress: Address
) {
    prepare(acct: AuthAccount) {
        let resolver = getAccount(contractAddress).contracts.borrow<&ViewResolver>(name: contractName)
            ?? panic("ViewResolver contract interface not found on contract address + name")
        
        let collectionData = resolver.resolveView(Type<MetadataViews.NFTCollectionData>())! as! MetadataViews.NFTCollectionData
        if acct.borrow<&AnyResource>(from: collectionData.storagePath) == nil {
            acct.save(<- collectionData.createEmptyCollection(), to: collectionData.storagePath)

            acct.link<&{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(collectionData.publicPath, target: collectionData.storagePath)
            acct.link<&{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, NonFungibleToken.Provider}>(collectionData.providerPath, target: collectionData.storagePath)
        }
        let receiverCap = acct.getCapability<&{NonFungibleToken.CollectionPublic}>(collectionData.publicPath)

        let expectedNftType = CompositeType(nftIdentifier) ?? panic("invalid nft identifier")

        let vault = acct.borrow<&{FungibleToken.Provider}>(from: paymentStoragePath)
            ?? panic("could not borrow token provider")

        let paymentVault <- vault.withdraw(amount: totalCost)

        let dropResolver = resolver.resolveView(Type<FlowtyDrops.DropResolver>())! as! FlowtyDrops.DropResolver
        let dropContainer = dropResolver.borrowContainer()
            ?? panic("unable to borrow drop container")

        let drop = dropContainer.borrowDropPublic(id: dropID) ?? panic("drop not found")

        let commissionReceiver = getAccount(commissionAddress).getCapability<&{FungibleToken.Receiver}>(paymentReceiverPath)
        let remainder <- drop.mint(
            payment: <-paymentVault,
            amount: numToMint,
            phaseIndex: dropPhaseIndex,
            expectedType: expectedNftType,
            receiverCap: receiverCap,
            commissionReceiver: commissionReceiver,
            data: {}
        )

        if remainder.balance > 0.0 {
            acct.borrow<&{FungibleToken.Receiver}>(from: paymentStoragePath)!.deposit(from: <-remainder)
        } else {
            destroy remainder
        }
    }
}