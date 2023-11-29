
import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction(receiver:Address, name:String) {

    prepare(signer: auth(Capabilities, Inbox) &Account) {
        //we issue a capability from our storage
        let storagePath = /storage/basicNFTMinter
        let capability = signer.capabilities.storage.issue<&BasicNFT.Minter>(storagePath)


        //we iterate through all controllers for this path and set the tag for the new one? is there a better way of doing this
        signer.capabilities.storage.forEachController(forPath:storagePath, fun(scc: &StorageCapabilityController) : Bool {
            if scc.tag == "" {
                scc.setTag(name)
                return false
            }
            return true
        })

        //we publis this capability to the inbox of the receiver
        signer.inbox.publish(capability, name:name, recipient:receiver)
    }
}
