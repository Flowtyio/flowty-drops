import "MetadataViews"
import "NonFungibleToken"

access(all) contract interface BaseNFTVars {
    access(all) let collectionDisplay: MetadataViews.NFTCollectionDisplay
    access(all) var totalMinted: UInt64

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}
}