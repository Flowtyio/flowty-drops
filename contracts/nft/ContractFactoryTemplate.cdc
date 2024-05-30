import "NonFungibleToken"
import "MetadataViews"
import "ViewResolver"

import "FlowtyDrops"
import "BaseNFT"
import "BaseNFTVars"
import "NFTMetadata"
import "UniversalCollection"
import "BaseCollection"

import "AddressUtils"

access(all) contract interface ContractFactoryTemplate {
    access(all) fun createContract(acct: auth(AddContract) &Account, name: String, params: {String: AnyStruct})

    access(all) fun getContractAddresses(): {String: Address} {
        let d: {String: Address} = {
            "NonFungibleToken": AddressUtils.parseAddress(Type<&{NonFungibleToken}>())!,
            "MetadataViews": AddressUtils.parseAddress(Type<&MetadataViews>())!,
            "ViewResolver": AddressUtils.parseAddress(Type<&{ViewResolver}>())!,
            "FlowtyDrops": AddressUtils.parseAddress(Type<&FlowtyDrops>())!,
            "BaseNFT": AddressUtils.parseAddress(Type<&{BaseNFT}>())!,
            "BaseNFTVars": AddressUtils.parseAddress(Type<&{BaseNFTVars}>())!,
            "NFTMetadata": AddressUtils.parseAddress(Type<&NFTMetadata>())!,
            "UniversalCollection": AddressUtils.parseAddress(Type<&UniversalCollection>())!,
            "BaseCollection": AddressUtils.parseAddress(Type<&{BaseCollection}>())!,
            "AddressUtils": AddressUtils.parseAddress(Type<&AddressUtils>())!
        }

        return d
    }

    access(all) fun importLine(name: String, addr: Address): String {
        return "import ".concat(name).concat(" from ").concat(addr.toString()).concat("\n")
    }

    access(all) fun generateImports(names: [String]): String {
        let addresses = self.getContractAddresses()
        var imports = ""
        for n in names {
            imports = imports.concat(self.importLine(name: n, addr: addresses[n] ?? panic("missing contract import address: ".concat(n))))
        }

        return imports
    }
}