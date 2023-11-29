
import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction(receiver:Address, name:String) {

    prepare(signer: auth(Capabilities, Inbox) &Account) {
        //we issue a capability from our storage
        let capability = signer.capabilities.storage.issue<&BasicNFT.Minter>(/storage/basicNFTMinter)

        //we publis this capability to the inbox of the receiver
        signer.inbox.publish(capability, name:name, recipient:receiver)
    }
}
