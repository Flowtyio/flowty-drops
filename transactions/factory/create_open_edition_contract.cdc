import "ContractFactory"
import "ContractFactoryTemplate"
import "OpenEditionTemplate"
import "MetadataViews"

transaction(name: String, params: {String: AnyStruct}) {
    prepare(acct: auth(AddContract) &Account) {
        ContractFactory.createContract(templateType: Type<OpenEditionTemplate>(), acct: acct, name: name, params: params)
    }
}