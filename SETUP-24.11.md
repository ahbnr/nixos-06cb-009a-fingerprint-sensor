There are two ways this flake can be used to drive the sensor:

1. Using uunicorn's [open-fprintd](https://github.com/uunicorn/open-fprintd) and [python-validity](https://github.com/uunicorn/python-validity).
  Starting with this setup is necessary since it supports fingerprint enrolling and gathering calibration data. However, it does not support authentication for enrolling. I.e. any user with physical access can register their fingerprint and can access fingerprint protected services. Thus, I recommend switching to backend (2) in the long term. Also, open-fprintd seems incompatible with some services relying on fingerprint authentication (e.g. the GDM screenlock).

2. Using the [libfprint-tod-vfs0090 fork by bingch](https://gitlab.com/bingch/libfprint-tod-vfs0090).
  This is slightly more complex to set up, but this driver integrates well with fprintd and thus proper authentication mechanisms are in place. Also, this approach is compatible with any service relying on fprintd.

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
    url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor?ref=24.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

And you need to add the module it exports in your outputs like this:

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
      nixos-06cb-009a-fingerprint-sensor.nixosModules."06cb-009a-fingerprint-sensor"
    ];
  };
};
```

For general information on using flakes with NixOS, see this guide: https://nixos.wiki/wiki/Flakes#Using_nix_flakes_with_NixOS

# Setup based on open-fprintd and python-validity

1. In your system configuration, enable the service and specify the `python-validity` backend:

```nix
services."06cb-009a-fingerprint-sensor" = {                                 
  enable = true;                                                            
  backend = "python-validity";                                              
};   
```

2. Rebuild your system.

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

4. Configure PAM to use the fingerprint sensor for authentication. E.g. to configure `sudo` to ask for a fingerprint, you need to adapt `security.pam.services.sudo.text`. However, this is quite fragile and it has broken for users across NixOS versions. Thus, I recommend switching to the second backend now which supports `sudo` authentication out of the box.

# Setup based on fprintd and bingch's driver

1. This driver can verify fingerprints, but it can not enroll them. Also, it requires some sensor calibration data which is extracted by python-validity.
   Hence, you first have to enroll your fingerprints with open-fprintd and python-validity using the steps described above.
   You do not need to setup any PAM configuration (step 4).

2. This will result in a file `/var/lib/python-validity/calib-data.bin` being generated. Copy this file to some path in your NixOS system configuration directory,
   e.g. `./calib-data.bin`

3. Now, update your configuration like this:
   ```nix
   services."06cb-009a-fingerprint-sensor" = {                                 
     enable = true;                                                            
     backend = "libfprint-tod";                                                
     calib-data-file = ./calib-data.bin;                
   }
   ```

   Here, the path `./calib-data.bin` should point to the calibration data you copied in step 1.

   This will enable the fprintd service that comes with the official package sources and configures it to use bingch's custom driver that is packaged with this flake.

4. Rebuild your system.
   The `fprintd` service might fail when being started immediately after shutting down `open-fprintd`, so you might need to restart the service manually once:

   ```sh
   systemctl restart fprintd
   ```

5. The fingerprint enrolling mechanism must be invoked again (i.e. repeat the `fprintd-enroll` invocation of step 1).
   Now, `fprintd` should function normally. By default NixOS comes with PAM configuration to use fingerprints for authenticating sudo. Also GDM now lets you log in using your fingerprint.

# Troubleshooting

In general, you can find troubleshooting and further usage information in the python-validity repository: https://github.com/uunicorn/python-validity
