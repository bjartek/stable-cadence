
import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction(receiver:Address) {

    prepare(signer: AuthAccount) {
        let minter =signer.borrow<&BasicNFT.Minter>(from: /storage/basicNFTMinter)!

        let cd = BasicNFT.getCollectionData()

 // Borrow the recipient's public NFT collection reference
        let collection = getAccount(receiver)
            .getCapability(cd.publicPath)
            .borrow<&{NonFungibleToken.Collection}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

         minter.mintNFT(metadata: {"Foo": "Bar"}, receiver:collection)

    }
}
