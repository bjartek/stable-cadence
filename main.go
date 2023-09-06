package main

import "github.com/bjartek/overflow"

func main() {

	o := overflow.Overflow(overflow.WithLogFull(), overflow.WithPrintResults(), overflow.WithFlowForNewUsers(10.0))

	if o.Error != nil {
		panic(o.Error)
	}

	o.Tx("setup", overflow.WithSigner("first"))

	o.Tx("mintNFT",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "first"),
	)
}
