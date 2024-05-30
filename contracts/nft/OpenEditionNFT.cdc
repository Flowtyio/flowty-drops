/*
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*
*/
import "NonFungibleToken"
import "MetadataViews"
import "ViewResolver"

import "FlowtyDrops"
import "BaseNFT"
import "BaseNFTVars"
import "NFTMetadata"
import "UniversalCollection"
import "BaseCollection"

access(all) contract OpenEditionNFT: BaseNFTVars, BaseCollection {
    access(all) var MetadataCap: Capability<&NFTMetadata.Container>
    access(all) var totalSupply: UInt64

    access(all) resource NFT: BaseNFT.NFT {
        access(all) let id: UInt64
        access(all) let metadataID: UInt64

        init() {
            OpenEditionNFT.totalSupply = OpenEditionNFT.totalSupply + 1
            self.id = OpenEditionNFT.totalSupply
            self.metadataID = 0
        }
    }

    access(all) resource NFTMinter: FlowtyDrops.Minter {
        access(contract) fun createNextNFT(): @{NonFungibleToken.NFT} {
            return <- create NFT()
        }
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- UniversalCollection.createCollection(nftType: Type<@NFT>())
    }

    init() {
        self.totalSupply = 0

        let square = MetadataViews.Media(
            file: MetadataViews.IPFSFile(
                cid: "QmWWLhnkPR3ejavNtzeJcdG9fwcBHKwBVEP4pZ9rGbdHEM",
                path: nil
            ),
            mediaType: "image/png"
        )

        let banner = MetadataViews.Media(
            file: MetadataViews.IPFSFile(
                cid: "QmYD8e5s59qYFFQXref1YzyqW1WKYUMPxfqVDEis2s23BF",
                path: nil
            ),
            mediaType: "image/png"
        )
        
        let collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: "The Open Edition Collection",
            description: "This collection is used as an example to help you develop your next Open Edition Flow NFT",
            externalURL: MetadataViews.ExternalURL("https://flowty.io"),
            squareImage: square,
            bannerImage: banner,
            socials: {
                "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")
            }
        )
        let collectionInfo = NFTMetadata.CollectionInfo(collectionDisplay: collectionDisplay)

        let acct: auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account = Account(payer: self.account)
        let cap = acct.capabilities.account.issue<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>()
        self.account.storage.save(cap, to: /storage/metadataAuthAccount)

        let caps = NFTMetadata.initialize(acct: acct.capabilities.account.issue<auth(SaveValue, IssueStorageCapabilityController, PublishCapability) &Account>().borrow()!, collectionInfo: collectionInfo)
        self.MetadataCap = caps.pubCap
        caps.ownerCap.borrow()!.addMetadata(id: 0, data: NFTMetadata.Metadata(
            name: "Fluid",
            description: "This is a sample open-edition NFT utilizing flowty drops for minting",
            thumbnail: MetadataViews.IPFSFile(cid: "QmWWLhnkPR3ejavNtzeJcdG9fwcBHKwBVEP4pZ9rGbdHEM", path: nil),
            traits: nil,
            editions: nil,
            externalURL: nil,
            data: {}
        ))

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.storage.save(<-minter, to: FlowtyDrops.MinterStoragePath)
        self.account.capabilities.storage.issue<&{FlowtyDrops.Minter}>(FlowtyDrops.MinterStoragePath)
    }
}