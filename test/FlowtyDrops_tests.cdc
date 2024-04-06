import Test
import "test_helpers.cdc"

pub fun setup() {
    deployAll()
}

pub fun testImports() {
    Test.assert(scriptExecutor("import_all.cdc", [])! as! Bool, message: "failed to import all")
}

