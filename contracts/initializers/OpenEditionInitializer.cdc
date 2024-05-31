import "ContractInitializer"
import "NFTMetadata"

access(all) contract OpenEditionInitializer: ContractInitializer {
    access(all) fun initialize(contractAcct: auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account, params: {String: AnyStruct}): NFTMetadata.InitializedCaps {
        pre {
            params["data"] != nil: "missing param data"
            params["data"]!.getType() == Type<NFTMetadata.Metadata>(): "data param must be of type NFTMetadata.Metadata"
            params["collectionInfo"] != nil: "missing param collectionInfo"
            params["collectionInfo"]!.getType() == Type<NFTMetadata.CollectionInfo>(): "collectionInfo param must be of type NFTMetadata.CollectionInfo"
        }

        let data = params["data"]! as! NFTMetadata.Metadata
        let collectionInfo = params["collectionInfo"]! as! NFTMetadata.CollectionInfo

        let acct: auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account = Account(payer: contractAcct)
        let cap = acct.capabilities.account.issue<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>()

        let t = self.getType()
        let contractName = t.identifier.split(separator: ".")[2]

        self.account.storage.save(cap, to: StoragePath(identifier: "metadataAuthAccount_".concat(contractName))!)

        return NFTMetadata.initialize(acct: acct, collectionInfo: collectionInfo, collectionType: self.getType())
    }
}