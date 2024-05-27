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

access(all) contract OpenEditionNFT: NonFungibleToken, ViewResolver {

    /// Total supply of ExampleNFTs in existence
    access(all) var totalSupply: UInt64

    /// The event that is emitted when the contract is created
    access(all) event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    access(all) event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    access(all) event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath

    /// The core resource that represents a Non Fungible Token.
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    access(all) resource NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let display: MetadataViews.Display

        init() {
            OpenEditionNFT.totalSupply = OpenEditionNFT.totalSupply + 1
            self.id = OpenEditionNFT.totalSupply

            self.display = MetadataViews.Display(
                name: "Fluid #".concat(self.id.toString()),
                description: "This is a sample open-edition NFT utilizing flowty drops for minting",
                thumbnail: MetadataViews.IPFSFile(cid: "QmWWLhnkPR3ejavNtzeJcdG9fwcBHKwBVEP4pZ9rGbdHEM", path: nil)
            )
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        access(all) fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>()
            ]
        }

        /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
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
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    access(all) resource Collection: NonFungibleToken.Collection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        init () {
            self.ownedNFTs <- {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        ///
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            assert(token.getType() == Type<@NFT>(), message: "invalid deposited nft type")

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@NFT>(): true}
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@NFT>()
        }

        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection so that
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        ///
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver} {
            let tmp = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
            let nft = tmp as! &OpenEditionNFT.NFT
            return tmp
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create Collection()
        }
    }

    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create Collection()
    }

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
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

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveContractView(resourceType: Type, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: OpenEditionNFT.CollectionStoragePath,
                    publicPath: OpenEditionNFT.CollectionPublicPath,
                    publicCollection: Type<&{NonFungibleToken.Collection}>(),
                    publicLinkedType: Type<&{NonFungibleToken.Collection}>(),
                    createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                        return <-OpenEditionNFT.createEmptyCollection(nftType: resourceType)
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
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

                return MetadataViews.NFTCollectionDisplay(
                    name: "The Open Edition Collection",
                    description: "This collection is used as an example to help you develop your next Open Edition Flow NFT",
                    externalURL: MetadataViews.ExternalURL("https://flowty.io"),
                    squareImage: square,
                    bannerImage: banner,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")
                    }
                )
            case Type<FlowtyDrops.DropResolver>():
                return FlowtyDrops.DropResolver(cap: OpenEditionNFT.account.capabilities.get<&{FlowtyDrops.ContainerPublic}>(FlowtyDrops.ContainerPublicPath))
        }
        return nil
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    access(all) fun getContractViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/openEditionNFT
        self.CollectionPublicPath = /public/openEditionNFT

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.storage.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(self.CollectionStoragePath),
            at: self.CollectionPublicPath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.storage.save(<-minter, to: FlowtyDrops.MinterStoragePath)
        self.account.capabilities.storage.issue<&{FlowtyDrops.Minter}>(FlowtyDrops.MinterStoragePath)

        emit ContractInitialized()
    }
}