import "NonFungibleToken"
import "BasicNFT"

transaction(receiver:Address) {


    let minter :&BasicNFT.Minter
    let collection : &{NonFungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {

        self.minter =signer.storage.borrow<&Capability<&BasicNFT.Minter>>(from: BasicNFT.minterPath)?.borrow()! ?? panic("your minter privileges has been revoked")

        let cd = BasicNFT.getCollectionData()
        self.collection = getAccount(receiver).capabilities.borrow<&{NonFungibleToken.Receiver}>(cd.publicPath) ?? panic("Could not get receiver reference to the NFT Collection")
    }

    execute {
        self.minter.mintNFT(metadata: {"Foo": "Bar"}, receiver:self.collection)
    }
}
