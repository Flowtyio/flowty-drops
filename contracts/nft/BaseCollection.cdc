import "NonFungibleToken"
import "StringUtils"
import "AddressUtils"
import "ViewResolver"
import "MetadataViews"
import "BaseNFTVars"
import "FlowtyDrops"


// A few primary challenges that have come up in thinking about how to define base-level interfaces
// for collections and NFTs:
// 
// - How do we resolve contract-level interfaces?
// - How do we track total supply/serial numbers for NFTs?
// - How do we store traits and medias?
//
// For some of these, mainly contract-level interfaces, we might be able to simply consolidate
// all of these into one contract interface and require that collection display (banner, thumbnail, name, description, etc.)
// be stored at the top-level of the contract so that they can be easily referenced later. This could make things easier in that we can
// make a base definition for anyone to use, but since it isn't a concrete definition, anyone can later override the pre-generated
// pieces to and modify the code to their liking. This could achieve the best of both worlds where there is minimal work to get something
// off the ground, but doesn't close the door to customization in the future. This could come at the cost of duplicated resource definitions,
// or could have the risk of circular imports depending on how we resolve certain pieces of information about a collection.
access(all) contract interface BaseCollection: ViewResolver {

    // The base collection is an interface that attmepts to take more boilerplate
    // off of NFT-standard compliant definitions.
    access(all) resource interface Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        access(all) var nftType: Type

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            pre {
                token.getType() == self.nftType: "unexpected nft type being deposited"
            }

            destroy self.ownedNFTs.insert(key: token.uuid, <-token)
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {
                self.nftType: true
            }
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == self.nftType
        }

        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            return <- self.ownedNFTs.remove(key: withdrawID)!
        }
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        if resourceType == nil {
            return nil
        }

        let rt = resourceType!
        let segments = rt.identifier.split(separator: ".") 
        let pathIdentifier = StringUtils.join([segments[2], segments[1]], "_")

        let addr = AddressUtils.parseAddress(rt)!
        let acct = getAccount(addr)
        
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                let segments = rt.identifier.split(separator: ".") 
                let pathIdentifier = StringUtils.join([segments[2], segments[1]], "_")

                return MetadataViews.NFTCollectionData(
                    storagePath: StoragePath(identifier: pathIdentifier)!,
                    publicPath: PublicPath(identifier: pathIdentifier)!,
                    publicCollection: Type<&{NonFungibleToken.Collection}>(),
                    publicLinkedType: Type<&{NonFungibleToken.Collection}>(),
                    createEmptyCollectionFunction: fun(): @{NonFungibleToken.Collection} {
                        let addr = AddressUtils.parseAddress(rt)!
                        let c = getAccount(addr).contracts.borrow<&{BaseNFTVars}>(name: segments[2])!
                        return <- c.createEmptyCollection(nftType: rt)
                    }
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let c = getAccount(addr).contracts.borrow<&{BaseNFTVars}>(name: segments[2])!
                return c.collectionDisplay
            case Type<FlowtyDrops.DropResolver>():
                return FlowtyDrops.DropResolver(cap: acct.capabilities.get<&{FlowtyDrops.ContainerPublic}>(FlowtyDrops.ContainerPublicPath))
        }

        return nil
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}
}