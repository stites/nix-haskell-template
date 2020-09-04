##
# haskell.nix helpers
#
# @file
# @version 0.1

package = PACKAGE-NAME
binary = PACKAGE-BINARY

lib:
	nix-build -A $(package).components.library

exe:
	nix-build -A $(package).components.exes.$(binary)

test:
	nix-build -A $(package).components.tests.$(package)-test

release:
	nix-build ./release.nix

development:
	nix-build ./nix/development.nix

# end
