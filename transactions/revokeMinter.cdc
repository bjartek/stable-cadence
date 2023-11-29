import "BasicNFT"

transaction(name: String) {

    prepare(signer: auth(StorageCapabilities) &Account) {
        signer.capabilities.storage.forEachController(forPath:BasicNFT.minterPath, fun(scc: &StorageCapabilityController) : Bool {
            if scc.tag == name {
                scc.delete()
                return false
            }
            return true
        })
    }
}
