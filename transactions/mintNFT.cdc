
import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction(receiver:Address) {

    let minter :&BasicNFT.Minter
    let collection : &{NonFungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {
        self.minter =signer.storage.borrow<&BasicNFT.Minter>(from: /storage/basicNFTMinter)!
        let cd = BasicNFT.getCollectionData()
        self.collection = getAccount(receiver).capabilities.borrow<&{NonFungibleToken.Receiver}>(cd.publicPath) ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        self.minter.mintNFT(metadata: {"Foo": "Bar"}, receiver:self.collection)
    }
}
