package main

import "github.com/bjartek/overflow"

func main() {

	o := overflow.Overflow(overflow.WithPrintResults())

	if o.Error != nil {
		panic(o.Error)
	}
}
