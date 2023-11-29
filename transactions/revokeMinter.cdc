import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction() {

    prepare(signer: auth(Capabilities) &Account) {
        //we get all capabilities for a given path and we delete them
        //
        let storagePath = /storage/basicNFTMinter
        let capability = signer.capabilities.storage.forEachController(forPath:storagePath, 
        fun(scc: &StorageCapabilityController) : Bool {
            scc.delete()
            return false
        })
    }
}
