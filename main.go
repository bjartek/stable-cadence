package main

import "github.com/bjartek/overflow"

func main() {
	o := overflow.Overflow(overflow.WithLogFull(), overflow.WithPrintResults(), overflow.WithFlowForNewUsers(10.0))

	if o.Error != nil {
		panic(o.Error)
	}

	o.Tx("setup", overflow.WithSigner("bob"))

	o.Tx("mintNFT",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "bob"),
	)

	name := "basicNFTMinterAlice"
	o.Tx("giveMinter",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "alice"),
		overflow.WithArg("name", name),
	)

	o.Tx("claimMinter",
		overflow.WithSigner("alice"),
		overflow.WithArg("name", name),
		overflow.WithArg("provider", "account"),
	)

	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("alice"),
		overflow.WithArg("receiver", "bob"),
	)

	o.Tx("revokeMinter", overflow.WithSignerServiceAccount())

	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("alice"),
		overflow.WithArg("receiver", "bob"),
	)
}
