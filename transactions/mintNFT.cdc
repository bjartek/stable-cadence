
import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction(receiver:Address) {

    prepare(signer: auth(BorrowValue) &Account) {
        let minter =signer.storage.borrow<&BasicNFT.Minter>(from: /storage/basicNFTMinter)!

        let cd = BasicNFT.getCollectionData()

        // Borrow the recipient's public NFT collection reference
        let collection = getAccount(receiver)
        .capabilities
        .borrow<&{NonFungibleToken.Receiver}>(cd.publicPath)
        ?? panic("Could not get receiver reference to the NFT Collection")

        minter.mintNFT(metadata: {"Foo": "Bar"}, receiver:collection)

    }
}
