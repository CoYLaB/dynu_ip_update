# Dynu IP Update Script

Simple script to update the [Dynu](https://www.dynu.com/) A record for a host with the IP of the current machine.
This comes particularly useful for cloud instances that do not use static IPs (an AWS EC2 example using cloud-init is given below).

The host name is retrieved from the configuration file `<install>/dynu.cfg`. 
The configuration file also contains the Dynu API token required to make the API calls for updating the record.

The sample file `<install>/SAMPLE-dynu.cfg` can be renamed and edited to replace the `HOST_NAME` and `API_TOKEN` variables.  

## Installation

1. Download and extract the files to any directory you want or alternatively clone the repository:

```bash
\t$git clone --sparse https://github.com/CoYLaB/dynu_ip_update.git /home/ec2-user/<install>
```

3. Copy `SAMPLE-dynu.cfg` to `dynu.cfg` in the same directory.
4. Edit the `HOST_NAME` variable and replace the `API_TOKEN` with your own Dynu authentication credential available from the [Control Panel](https://www.dynu.com/en-US/ControlPanel/APICredentials).
5. Make the script executable
```$chmod u+x <install>/dynu_ip_update.sh```

## Running the script

At a command prompt run the following command:

```bash <install>/dynu_ip_update.sh
```
