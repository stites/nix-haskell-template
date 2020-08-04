##
# haskell.nix helpers
#
# @file
# @version 0.1

package = clight-cli


lib:
	nix-build -A $(package).components.library

exe:
	nix-build -A $(package).components.exe.$(package)

# end
