
import "NonFungibleToken"
import "BasicNFT"
import "CompositeNFT"
import "UniversalCollection"
import "MetadataViews"

transaction(receiver:Address, basicID:UInt64) {

    let compositeMinter: &CompositeNFT.Minter
    let collection : &{NonFungibleToken.Receiver}
    let basicCollection : &{NonFungibleToken.Provider}

    prepare(signer: auth(BorrowValue, NonFungibleToken.Withdrawable) &Account) {
        self.compositeMinter =signer.storage.borrow<&CompositeNFT.Minter>(from: CompositeNFT.minterPath)!
        let cd = CompositeNFT.getCollectionData()
        self.collection = getAccount(receiver).capabilities.borrow<&{NonFungibleToken.Receiver}>(cd.publicPath) ?? panic("Could not get receiver reference to the NFT Collection")

        let bcd = BasicNFT.getCollectionData()
        self.basicCollection=signer.storage.borrow<&{NonFungibleToken.Provider}>(from: bcd.storagePath) ?? panic("cannot get sub nft path")
    }

    execute {
        let child <-  self.basicCollection.withdraw(id: basdicID)
        self.minter.mintNFT(metadata: {"Foo": "Bar"}, receiver:self.collection, child: <- child)
    }
}
