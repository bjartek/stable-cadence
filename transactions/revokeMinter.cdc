import "BasicNFT"

transaction(name: String) {

    prepare(signer: auth(StorageCapabilities) &Account) {
        signer.capabilities.storage.forEachController(
            forPath:BasicNFT.minterPath, 
            revokeWithTag(tag: name)
        )
    }
}


access(all)
fun revokeWithTag(tag:String) : fun(&StorageCapabilityController): Bool {
    return fun(scc: &StorageCapabilityController) : Bool {
        if scc.tag == tag {
            scc.delete()
            return false
        }
        return true
    }
}
