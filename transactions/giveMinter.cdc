import "BasicNFT"

transaction(receiver:Address, name:String) {

    prepare(signer: auth(StorageCapabilities, PublishInboxCapability) &Account) {
        //we issue a capability from our storage
        let capability = signer.capabilities.storage.issue<&BasicNFT.Minter>(BasicNFT.minterPath)

        //we iterate through all controllers for this path and set the tag for the new one.
        signer.capabilities.storage.forEachController(forPath:BasicNFT.minterPath, fun(scc: &StorageCapabilityController) : Bool {
            if scc.tag == "" {
                scc.setTag(name)
                return false
            }
            return true
        })

        //we publish this capability to the inbox of the receiver
        signer.inbox.publish(capability, name:name, recipient:receiver)
    }
}
