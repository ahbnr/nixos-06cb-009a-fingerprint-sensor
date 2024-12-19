This Nix flake packages the necessary software for driving the 06cb:009a fingerprint sensor (used in ThinkPads like the T480 or T480s).
It has been tested with a T480.

> [!IMPORTANT]  
> I rarely use my T480 nowadays and I only use NixOS stable. I.e. this flake will likely only receive updates whenever a new NixOS stable version is released.
>
> I do not take any responsibility for any issues caused by the use of this flake.

# How to Use

* With NixOS Unstable: Not supported. You can try the instructions for 24.11, though.
* With NixOS 24.11: See [SETUP-24.11.md](./SETUP-24.11.md).
* With NixOS 23.11: Check out the branch [`23.11`](https://github.com/ahbnr/nixos-06cb-009a-fingerprint-sensor/tree/23.11) and follow the instructions in the `README.md` on that branch.
