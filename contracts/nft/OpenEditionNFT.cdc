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
import "FungibleToken"
import "FlowToken"

import "FlowtyDrops"
import "FlowtySwitchers"
import "FlowtyAddressVerifiers"
import "FlowtyPricers"
import "DropFactory"
import "BaseCollection"
import "BaseNFTVars"

access(all) contract OpenEditionNFT: NonFungibleToken, BaseCollection, BaseNFTVars {
    access(all) let collectionDisplay: MetadataViews.NFTCollectionDisplay
    access(all) var totalMinted: UInt64

    access(all) resource NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let display: MetadataViews.Display

        init() {
            OpenEditionNFT.totalMinted = OpenEditionNFT.totalMinted + 1
            self.id = OpenEditionNFT.totalMinted

            self.display = MetadataViews.Display(
                name: "Fluid #".concat(self.id.toString()),
                description: "This is a sample open-edition NFT utilizing flowty drops for minting",
                thumbnail: MetadataViews.IPFSFile(cid: "QmWWLhnkPR3ejavNtzeJcdG9fwcBHKwBVEP4pZ9rGbdHEM", path: nil)
            )
        }

        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return self.display
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://flowty.io/asset/".concat(OpenEditionNFT.account.address.toString()).concat("/OpenEditionNFT/").concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return OpenEditionNFT.resolveContractView(resourceType: self.getType(), viewType: view)
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return OpenEditionNFT.resolveContractView(resourceType: self.getType(), viewType: view)
            }

            return nil
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create Collection()
        }
    }

    // DONE
    access(all) resource Collection: BaseCollection.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        access(all) var nftType: Type

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create Collection()
        }

        init () {
            self.ownedNFTs <- {}
            self.nftType = Type<@NFT>()
        }
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create Collection()
    }

    access(all) resource NFTMinter: FlowtyDrops.Minter {
        access(all) fun mint(payment: @{FungibleToken.Vault}, amount: Int, phase: &FlowtyDrops.Phase, data: {String: AnyStruct}): @[{NonFungibleToken.NFT}] {
            switch(payment.getType()) {
                case Type<@FlowToken.Vault>():
                    OpenEditionNFT.account.storage.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault)!.deposit(from: <-payment)
                    break
                default:
                    panic("unsupported payment token type")
            }

            let nfts: @[{NonFungibleToken.NFT}] <- []

            var count = 0
            while count < amount {
                count = count + 1
                nfts.append(<- create NFT())
            }

            return <- nfts
        }
    }

    init() {
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
        
        self.collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: "The Open Edition Collection",
            description: "This collection is used as an example to help you develop your next Open Edition Flow NFT",
            externalURL: MetadataViews.ExternalURL("https://flowty.io"),
            squareImage: square,
            bannerImage: banner,
            socials: {
                "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")
            }
        )

        self.totalMinted = 0
        let cd: MetadataViews.NFTCollectionData = self.resolveContractView(resourceType: Type<@NFT>(), viewType: Type<MetadataViews.NFTCollectionData>())! as! MetadataViews.NFTCollectionData

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.storage.save(<-collection, to: cd.storagePath)

        // create a public capability for the collection
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath),
            at: cd.publicPath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.storage.save(<-minter, to: FlowtyDrops.MinterStoragePath)
        self.account.capabilities.storage.issue<&{FlowtyDrops.Minter}>(FlowtyDrops.MinterStoragePath)
    }
}