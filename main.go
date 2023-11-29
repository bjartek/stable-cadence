package main

import "github.com/bjartek/overflow"

func main() {
	o := overflow.Overflow(overflow.WithLogFull(), overflow.WithPrintResults(), overflow.WithFlowForNewUsers(10.0))

	if o.Error != nil {
		panic(o.Error)
	}

	o.Tx("setup", overflow.WithSigner("bob"))

	// We create a minter and give it to alice
	name := "basicNFTMinterAlice"
	o.Tx("giveMinter",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "alice"),
		overflow.WithArg("name", name),
	)

	// Alice claims the minter from her inbox
	o.Tx("claimMinter",
		overflow.WithSigner("alice"),
		overflow.WithArg("name", name),
		overflow.WithArg("provider", "account"),
	)

	// We mint the NFT as this admin
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("alice"),
		overflow.WithArg("receiver", "bob"),
	)

	// the admin revokes the permission
	o.Tx("revokeMinter", overflow.WithSignerServiceAccount())

	// we get an error minting again
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("alice"),
		overflow.WithArg("receiver", "bob"),
	)
}
