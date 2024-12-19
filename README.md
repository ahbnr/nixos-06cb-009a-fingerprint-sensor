This Nix flake packages the necessary software for driving the 06cb:009a fingerprint sensor (used in ThinkPads like the T480 or T480s).
It has been tested with a T480. With some small changes, the flake can probably also be used to setup the sensor 138a:0097 used in other ThinkPads (untested!). See further info below.

I do not take any responsibility for any issues caused by the use of this flake.

There are two ways this flake can be used to drive the sensor:

1. Using uunicorn's [open-fprintd](https://github.com/uunicorn/open-fprintd) and [python-validity](https://github.com/uunicorn/python-validity). The setup is more straightforward but this solution does not support authentication for fingerprint enrolling. I.e. any user with physical access can register their fingerprint and can access fingerprint protected services. Also, open-fprintd seems incompatible with some services relying on fingerprint authentication (e.g. the GDM screenlock). However, this setup should be compatible with the 138a:0097 sensor without any changes (untested!).

2. Using the [libfprint-tod-vfs0090 fork by bingch](https://gitlab.com/bingch/libfprint-tod-vfs0090). This is slightly more complex to set up, but this driver integrates well with fprintd and thus proper authentication mechanisms are in place. Also, this approach is compatible with any service relying on fprintd. With a small change as described below, this setup is probably also compatible with the 138a:0097 sensor (untested!).

# Table of Contents

* [Loading the flake](#loading-this-flake)
* [Setup based on open-fprintd and python-validity](#setup-based-on-open-fprintd-and-python-validity)
* [Setup based on fprintd and bingch's driver](#setup-based-on-fprintd-and-bingchs-driver)
* [Troubleshooting](#troubleshooting)

# Loading this flake

You can add this flake to your inputs like this:
```nix
inputs = {
  # ...

  nixos-06cb-009a-fingerprint-sensor = {
    url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor?ref=23.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

For general information on using flakes with NixOS, see this guide: https://nixos.wiki/wiki/Flakes#Using_nix_flakes_with_NixOS

# Setup based on open-fprintd and python-validity

1. Load the open-fprintd and python-validity modules in your outputs:

```nix
outputs = {
  self, nixpkgs,
  # ...
  nixos-06cb-009a-fingerprint-sensor,
  ...
}: {
  nixosConfigurations.<myhostname> = nixpkgs.lib.nixosSystem {
    # ...
    modules = [
      # ...
      nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
      nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
    ];
  };
};
```

2. In your system configuration, enable the open-fprintd and python-validity services:

```nix
services.open-fprintd.enable = true;
services.python-validity.enable = true;
```

Also, you need to make sure, `services.fprintd` is not enabled, and `fprintd` is not in your `systemPackages`, otherwise conflicts may arise.

3. Rebuild your system.

3. You can now register fingerprints for a user with `fprintd-enroll` and also use all the other `fprintd-` user tooling.
   More information and some troubleshooting help can be found in the python-validity repository: https://github.com/uunicorn/python-validity

   Furthermore, if this is the first time you are using `python-validity` with your fingerprint sensor then you might need to download the appropriate firmware and upload it to the sensor. Luckily, `python-validity` already comes with scripts that automatically download the right firmware and install it.

   In short, if you get an error `list_devices failed` and/or `journalctl -u python3-validity` contains an error similar to `FileNotFoundError: [Errno 2] No such file or directory: '/tmp/python-validity/6_07f_lenovo_mis_qm.xpfwext'`, then you can download and install the firmware like this (run this as root!):
   ```sh
   systemctl stop python3-validity
   validity-sensors-firmware
   systemctl start python3-validity
   ```

   Afterwards, try enrolling your fingerprint again.

4. Configure PAM to use the fingerprint sensor for authentication. E.g. for configuring `sudo` to ask for a fingerprint, you can use this configuration:

```nix
# fingerprint scanning for authentication
# (this makes it so that it prompts for a password first. If none is entered or an incorrect one is entered, it will ask for a fingerprint instead)
security.pam.services.sudo.text = ''
  # Account management.
  account required pam_unix.so
  
  # Authentication management.
  auth sufficient pam_unix.so   likeauth try_first_pass nullok
  auth sufficient ${nixos-06cb-009a-fingerprint-sensor.localPackages.fprintd-clients}/lib/security/pam_fprintd.so
  auth required pam_deny.so
  
  # Password management.
  password sufficient pam_unix.so nullok sha512
  
  # Session management.
  session required pam_env.so conffile=/etc/pam/environment readenv=0
  session required pam_unix.so
'';
```

For this, `nixos-06cb-009a-fingerprint-sensor` needs to be available in your configuration, see [this troubleshooting step](#error-undefined-variable-nixos-06cb-009a-fingerprint-sensor).


# Setup based on fprintd and bingch's driver

1. This driver can verify fingerprints, but it can not enroll them. Also, it requires some sensor calibration data which is extracted by python-validity.
   Hence, you first have to enroll your fingerprints with open-fprintd and python-validity using the steps described above.
   You do not need to setup any PAM configuration (step 4).

  This will result in a file `/var/lib/python-validity/calib-data.bin` being generated. Copy this file to some path in your NixOS system configuration directory,
  e.g. `./calib-data.bin`

2. Now, we can remove open-fprintd and python-validity again.
   E.g. remove these modules:

   ```nix
   nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
   nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
   ```

   and comment out or remove the services:
   ```nix
   services.open-fprintd.enable = true;
   services.python-validity.enable = true;
   ```

   If you had setup any PAM configuration relying on `nixos-06cb-009a-fingerprint-sensor.localPackages.fprintd-clients` you also need to remove it.

3. Now, enable the fprintd service that comes with the official package source and configure it to use bingch's custom driver supplied by this flake:

   ```nix
   services.fprintd = {
     enable = true;
     tod = {
       enable = true;
       driver = nixos-06cb-009a-fingerprint-sensor.lib.libfprint-2-tod1-vfs0090-bingch {
         calib-data-file = ./calib-data.bin;
       };
     };
   };
   ```

   Here, the path `./calib-data.bin` should point to the calibration data you copied in step 1.
   Also, `nixos-06cb-009a-fingerprint-sensor` needs to be available in your configuration, see [this troubleshooting step](#error-undefined-variable-nixos-06cb-009a-fingerprint-sensor).

   Furthermore, if you are using the sensor 138a:0097 and not 06cb:009a, you might still be able to make this work by using the original
   [libfprint-tod-vfs0090 driver by Marco Trevisan](https://gitlab.freedesktop.org/3v1n0/libfprint-tod-vfs0090) instead of bingch's fork.
   That driver is part of the official NixOS packages and it does not require the calibration data file.
   Hence, the following configuration might work for 138a:0097 (untested):
   ```nix
   services.fprintd = {
     enable = true;
     tod = {
       enable = true;
       driver = pkgs.libfprint-2-tod1-vfs0090;
     };
   };
   ```

4. Rebuild your system.
   The `fprintd` service might fail when being started immediately after shutting down `open-fprintd`, so you might need to restart the service manually once:

   ```sh
   systemctl restart fprintd
   ```

5. The fingerprint enrolling mechanism must be invoked again (i.e. repeat the `fprintd-enroll` invocation of step 1).
   Now, `fprintd` should function normally. By default NixOS comes with PAM configuration to use fingerprints for authenticating sudo. Also GDM now lets you log in using your fingerprint.

# Troubleshooting

In general, you can find troubleshooting and further usage information in the python-validity repository: https://github.com/uunicorn/python-validity
However, there is also some troubleshooting information specific to this flake in the following sections:

## Error: `undefined variable 'nixos-06cb-009a-fingerprint-sensor'`

For some of the setup steps, you need access to the `nixos-06cb-009a-fingerprint-sensor` input in your configuration.
If you are not placing this configuration in your `flake.nix` file but if you are using an external configuration file like `configuration.nix` instead, you need to pass on the `nixos-06cb-009a-fingerprint-sensor` input to that configuration file.

You can do this by filling the `specialArgs` parameter of `nixosSystem` with your flake inputs.
I.e. capture your flake inputs in a variable `attrs` like this:
```nix
outputs = {
  self, nixpkgs,
  # ...
  nixos-06cb-009a-fingerprint-sensor,
  ...
}@attrs {
  ...
}
```

Then set `specialArgs = attrs;` in your `nixosSystem` call like this:
```nix
nixosConfigurations.<myhostname> = nixpkgs.lib.nixosSystem {
  # ...
  specialArgs = attrs;
  modules = [
    # ...
  ];
};
```

Finally, specify `nixos-06cb-009a-fingerprint-sensor` as an argument of your external configuration file.
E.g. your `configuration.nix` should start like this:
```nix
{ config, pkgs, lib, nixos-06cb-009a-fingerprint-sensor, ... }:
```

Now, `nixos-06cb-009a-fingerprint-sensor` should be available as a variable in your configuration.
