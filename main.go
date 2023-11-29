package main

import (
	"fmt"

	"github.com/bjartek/overflow"
)

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

	// bob is a minter
	bobName := "basicNFTMinterBob"
	o.Tx("giveMinter",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "bob"),
		overflow.WithArg("name", bobName),
	)

	// bob claims the minter from her inbox
	o.Tx("claimMinter",
		overflow.WithSigner("bob"),
		overflow.WithArg("name", bobName),
		overflow.WithArg("provider", "account"),
	)

	// We mint the NFT as this admin
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("bob"),
		overflow.WithArg("receiver", "bob"),
	)

	// the admin revokes the permission
	o.Tx("revokeMinter",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("name", name))

	// bob should still be able to mint
	// we get an error minting again
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("bob"),
		overflow.WithArg("receiver", "bob"),
	)

	fmt.Println("We should now get an error when minting as alice")
	fmt.Scanln()
	// we get an error minting
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("alice"),
		overflow.WithArg("receiver", "bob"),
	)
}
