# tetr
Tiny Core tc-ext-tools and remaster

## Build
`make all`

* Build x86 only
`make x86`

* Build x86_64 only
`make x86_64`

* Force a rebuild
`make force_all`

* Rebuild x86 only
`make force`

* Rebuild x86_64 only
`make force_64`

## Updates

Ideally, only the Makefile will now need to be updated to move to a new
version of tinycore.

Update the TC_VERSION field of the Makefile to begin the upgrade process.
