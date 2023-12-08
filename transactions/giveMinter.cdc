import "BasicNFT"

transaction(receiver:Address, name:String) {

    prepare(signer: auth(StorageCapabilities, PublishInboxCapability) &Account) {
        //we issue a capability from our storage
        let capability = signer.capabilities.storage.issue<&BasicNFT.Minter>(BasicNFT.minterPath)

        //we set the name as tag so it is easy for us to revoke it later using a friendly name
        let capcon = storage.getController(byCapabilityID:capability.id)!
        capcon.setTag(name)

        //we publish this capability to the inbox of the receiver
        signer.inbox.publish(capability, name:name, recipient:receiver)
    }
}
