import "NonFungibleToken"
import "MetadataViews"

access(all) contract BaseNFTMetadata {
    access(all) struct NFTMetadata {

    }

    access(all) resource MetadataContainer {
        access(all) let metadata: {UInt64: NFTMetadata}
    }
}