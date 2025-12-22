Mount **so-auto.iso**

`sudo mkdir /mnt/iso`<br>
`/home/tester/SecurityOnion/setup/`

``` bash
# mount_and_copy.sh
sudo mount /dev/cdrom /mnt/iso
sudo cp /mnt/iso/so-* .
sudo chmod +x so-manager.sh
sudo chmod +x so-whiptail.manager
```

`sudo chmod +x mount_and_copy.sh`<br>
`./mount_and_copy.sh`