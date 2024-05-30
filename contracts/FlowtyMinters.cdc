import "FungibleToken"
import "NonFungibleToken"
import "FlowtyDrops"
import "NFTMetadata"
import "AddressUtils"

access(all) contract interface FlowtyMinters {
    access(all) resource interface Minter: FlowtyDrops.Minter {
    }
}