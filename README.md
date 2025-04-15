# Fork of official iPXE project in an attempt to permanently fix some broadcom fuckery

This fork modifies the official iPXE project to address specific issues with certain Broadcom network interfaces.

* Added debug output in `src/usr/ifmgmt.c` so that it will now show `Configuring (net0 b0:26:28:f3:3b:ce) [Driver: nii PCI: XXXX:YYYY]...... ok`
* Changed `NUM_RX_BUFFERS` from 8 to 2 in `src/drivers/net/bnxt/bnxt.h` based on [this comment](https://github.com/ipxe/ipxe/issues/1023#issuecomment-2188474322).
* Commented out the bnxt driver entry for `14e4-16D6` in `src/drivers/net/bnxt/bnxt.c`.

# Build Instructions:
1.  **Required Packages**
    ```bash
    sudo apt-get install -y git gcc make liblzma-dev tar
    ```


2.  **Clone the repository:**
    ```bash
    git clone https://github.com/HotelMoted/ipxe.git
    ```

3.  **Navigate into the src directory:**
    ```bash
    cd ipxe/src
    ```

4.  **Create your custom iPXE script:**
    ```bash
    nano myscript.ipxe
    ```
    **Remember to replace `ip.ip.ip.ip` with your server's actual IP address or hostname.**

    ```ipxe
    #!ipxe
    dhcp
    chain http://ip.ip.ip.ip/kickstart.php/mypreseedpost
    ```

5.  **Build and Package the EFI binary:**
    ```bash
    make bin-x86_64-efi/ipxe.efi EMBED=myscript.ipxe && tar czvf ipxe$(date +%Y%m%d%H%M).tgz bin-x86_64-efi/ipxe.efi && find "$(pwd)" -name '*.tgz' -ls
    ```
