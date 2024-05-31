import "ContractFactoryTemplate"
import "MetadataViews"
import "NFTMetadata"

access(all) contract OpenEditionTemplate: ContractFactoryTemplate {
    access(all) fun createContract(acct: auth(AddContract) &Account, name: String, params: {String: AnyStruct}) {
        let code = self.generateImports(names: [
            "NonFungibleToken",
            "MetadataViews",
            "ViewResolver",
            "FlowtyDrops",
            "BaseNFT",
            "BaseCollection",
            "NFTMetadata",
            "UniversalCollection",
            "BaseCollection",
            "AddressUtils"
        ]).concat("\n\n"
        .concat("access(all) contract ").concat(name).concat(": BaseCollection {\n")
        .concat("    access(all) var MetadataCap: Capability<&NFTMetadata.Container>\n")
        .concat("    access(all) var totalSupply: UInt64\n")
        .concat("\n\n")
        .concat("    access(all) resource NFT: BaseNFT.NFT {\n")
        .concat("        access(all) let id: UInt64\n")
        .concat("        access(all) let metadataID: UInt64\n")
        .concat("\n")
        .concat("        init() {\n")
        .concat("            ").concat(name).concat(".totalSupply = ").concat(name).concat(".totalSupply + 1\n")
        .concat("            self.id = ").concat(name).concat(".totalSupply\n")
        .concat("            self.metadataID = 0\n")
        .concat("        }\n")
        .concat("    }\n")
        .concat("\n\n")
        .concat("    access(all) resource NFTMinter: FlowtyDrops.Minter {\n")
        .concat("        access(contract) fun createNextNFT(): @{NonFungibleToken.NFT} {\n")
        .concat("            return <- create NFT()\n")
        .concat("        }\n")
        .concat("    }\n")
        .concat("\n\n")
        .concat("    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {\n")
        .concat("        return <- UniversalCollection.createCollection(nftType: Type<@NFT>())\n"))
        .concat("    }\n")
        .concat("\n\n")
        .concat("    init(collectionDisplay: MetadataViews.NFTCollectionDisplay, data: NFTMetadata.Metadata) {\n")
        .concat("        self.totalSupply = 0\n")
        .concat("        let collectionInfo = NFTMetadata.CollectionInfo(collectionDisplay: collectionDisplay)\n")
        .concat("\n\n")
        .concat("        let acct: auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account = Account(payer: self.account)\n")
        .concat("        let cap = acct.capabilities.account.issue<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>()\n")
        .concat("        self.account.storage.save(cap, to: /storage/metadataAuthAccount_").concat(name).concat(")\n")
        .concat("\n\n")
        .concat("        let caps = NFTMetadata.initialize(acct: acct.capabilities.account.issue<auth(SaveValue, IssueStorageCapabilityController, PublishCapability) &Account>().borrow()!, collectionInfo: collectionInfo)\n")
        .concat("        self.MetadataCap = caps.pubCap\n")
        .concat("        caps.ownerCap.borrow()!.addMetadata(id: 0, data: data)\n")
        .concat("\n\n")
        .concat("        let minter <- create NFTMinter()\n")
        .concat("        self.account.storage.save(<-minter, to: FlowtyDrops.getMinterStoragePath(type: self.getType()))\n")
        .concat("        self.account.capabilities.storage.issue<&{FlowtyDrops.Minter}>(FlowtyDrops.getMinterStoragePath(type: self.getType()))\n")
        .concat("    }\n")
        .concat("}\n")

        acct.contracts.add(name: name, code: code.utf8, params["collectionDisplay"]! as! MetadataViews.NFTCollectionDisplay, params["data"]! as! NFTMetadata.Metadata)
    }
}
