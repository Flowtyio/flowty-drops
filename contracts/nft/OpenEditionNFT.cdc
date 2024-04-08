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
import "ExampleToken"

import "FlowtyDrops"
import "FlowtySwitches"
import "FlowtyAddressVerifiers"
import "FlowtyPricers"
import "DropFactory"

pub contract OpenEditionNFT: NonFungibleToken, ViewResolver {

    /// Total supply of ExampleNFTs in existence
    pub var totalSupply: UInt64

    /// The event that is emitted when the contract is created
    pub event ContractInitialized()

    /// The event that is emitted when an NFT is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)

    /// The event that is emitted when an NFT is deposited to a Collection
    pub event Deposit(id: UInt64, to: Address?)

    /// Storage and Public Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    /// The core resource that represents a Non Fungible Token.
    /// New instances will be created using the NFTMinter resource
    /// and stored in the Collection resource
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let display: MetadataViews.Display

        init() {
            OpenEditionNFT.totalSupply = OpenEditionNFT.totalSupply + 1
            self.id = OpenEditionNFT.totalSupply

            self.display = MetadataViews.Display(
                name: "Fluid #".concat(self.id.toString()),
                description: "This is a sample open-edition NFT utilizing flowty drops for minting",
                thumbnail: MetadataViews.IPFSFile(cid: "QmNtDmxuyBeA6YJht3ADMJCCqLoG3SPf3S7DYavZTeFUy7", path: nil)
            )
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
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
        pub fun resolveView(_ view: Type): AnyStruct? {
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
                    return OpenEditionNFT.resolveView(view)
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return OpenEditionNFT.resolveView(view)
            }
            return nil
        }
    }

    /// The resource that will be holding the NFTs inside any account.
    /// In order to be able to manage NFTs any account will need to create
    /// an empty collection first
    ///
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        /// Removes an NFT from the collection and moves it to the caller
        ///
        /// @param withdrawID: The ID of the NFT that wants to be withdrawn
        /// @return The NFT resource that has been taken out of the collection
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Adds an NFT to the collections dictionary and adds the ID to the id array
        ///
        /// @param token: The NFT resource to be included in the collection
        ///
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @OpenEditionNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Helper method for getting the collection IDs
        ///
        /// @return An array containing the IDs of the NFTs in the collection
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets a reference to an NFT in the collection so that
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        /// Gets a reference to an NFT in the collection so that
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///
        pub fun borrowExampleNFT(id: UInt64): &OpenEditionNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &OpenEditionNFT.NFT
            }

            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        ///
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let OpenEditionNFT = nft as! &OpenEditionNFT.NFT
            return OpenEditionNFT
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// Allows anyone to create a new empty collection
    ///
    /// @return The new Collection resource
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    pub resource NFTMinter: FlowtyDrops.Minter {
        pub fun mint(payment: @FungibleToken.Vault, amount: Int, phase: &FlowtyDrops.Phase, data: {String: AnyStruct}): @[NonFungibleToken.NFT] {
            switch(payment.getType()) {
                case Type<@FlowToken.Vault>():
                    OpenEditionNFT.account.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault)!.deposit(from: <-payment)
                    break
                case Type<@ExampleToken.Vault>():
                    OpenEditionNFT.account.borrow<&{FungibleToken.Receiver}>(from: /storage/exampleTokenVault)!.deposit(from: <-payment)
                    break
                default:
                    panic("unsupported payment token type")
            }

            let nfts: @[NonFungibleToken.NFT] <- []

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
    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: OpenEditionNFT.CollectionStoragePath,
                    publicPath: OpenEditionNFT.CollectionPublicPath,
                    providerPath: /private/openEditionNFT,
                    publicCollection: Type<&OpenEditionNFT.Collection{NonFungibleToken.CollectionPublic}>(),
                    publicLinkedType: Type<&OpenEditionNFT.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&OpenEditionNFT.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-OpenEditionNFT.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
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
                    squareImage: media,
                    bannerImage: media,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")
                    }
                )
            case Type<FlowtyDrops.DropResolver>():
                return FlowtyDrops.DropResolver(cap: OpenEditionNFT.account.getCapability<&{FlowtyDrops.ContainerPublic}>(FlowtyDrops.ContainerPublicPath))
        }
        return nil
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    pub fun getViews(): [Type] {
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
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&OpenEditionNFT.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: FlowtyDrops.MinterStoragePath)
        let minterCap = self.account.link<&NFTMinter{FlowtyDrops.Minter}>(FlowtyDrops.MinterPrivatePath, target: FlowtyDrops.MinterStoragePath)
            ?? panic("unable to link minter capability")

        emit ContractInitialized()
    }
}