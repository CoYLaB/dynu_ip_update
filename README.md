# Dynu IP Update Script

Simple script to update the [Dynu](https://www.dynu.com/) A record for a host with the IP of the current machine.

The host name is retrieved from the configuration file `<install>/dynu.cfg`. 
The configuration file also contains the Dynu API token required to make the API calls for updating the record.

The sample file `<install>/SAMPLE-dynu.cfg` can be renamed and edited to replace the `HOST_NAME` and `API_TOKEN` variables.  

## Installation

1. Download and extract the files to any directory you want or alternatively clone the repository:

```bash git clone --sparse https://github.com/CoYLaB/dynu_ip_update.git /home/ec2-user/<install>```
3. Copy `SAMPLE-dynu.cfg` to `dynu.cfg` in the same directory.
4. Edit the `HOST_NAME` variable and replace the `API_TOKEN` with your own Dynu authentication credential available from the [Control Panel](https://www.dynu.com/en-US/ControlPanel/APICredentials).

## Running the script
