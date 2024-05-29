import "MetadataViews"
import "NonFungibleToken"
import "NFTMetadata"

access(all) contract interface BaseNFTVars {
    access(all) var MetadataCap: Capability<&NFTMetadata.Container>
    access(all) var totalSupply: UInt64
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}
}