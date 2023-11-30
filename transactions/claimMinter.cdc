import "BasicNFT"

transaction(provider:Address, name:String) {

    prepare(signer: auth(ClaimInboxCapability, SaveValue) &Account) {

        //we get the capability from our inbox
        let capability = signer.inbox.claim<&BasicNFT.Minter>(name, provider:provider)!

        signer.storage.save(capability, to: BasicNFT.minterPath)
    }
}
