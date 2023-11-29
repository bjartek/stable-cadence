import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction(name: String) {

    prepare(signer: auth(Capabilities) &Account) {
        //we get all capabilities for a given path and we delete them
        //
        let storagePath = /storage/basicNFTMinter
        let capability = signer.capabilities.storage.forEachController(forPath:storagePath, fun(scc: &StorageCapabilityController) : Bool {

            if scc.tag == name {
                scc.delete()
                return false
            }
            return true
        })
    }
}
