# How to Demo File Repair

There's a script to automate the technical portions of the file repair process.

## Run Script

`$ ssh -t deploy@figgy-staging2 -C "cd /opt/figgy/current && ./bin/rails runner scripts/fixity_demo.rb"`

This will create three resources (Bad Local File Set, Bad Cloud File Set, and Bad Local & Cloud File Set) and prompt you for input when everything is
preserved. Check https://figgy-staging.princeton.edu/sidekiq to make sure no
jobs are running, then hit enter. This will corrupt the files.

### Bad Local File Demo

You will be prompted to run a cloud fixity check on the "Bad Local File Set"
resource. Find it in Figgy, go its first File Set, and take note of the cloud
fixity date (there may be none). Hit enter, refresh, and continue when that date increases.

You'll be prompted to run a local fixity check and repair. Download the local
file, show that it's broken, hit enter, wait for the local fixity check date to
increase, and then download again - the file should be repaired.

### Bad Cloud File Demo

You will be prompted run a local fixity check. Find the bad cloud file set item
in Figgy, go to its first File Set, and take note of the local fixity date. Hit
enter in the terminal, refresh, and continue when that date increases.

You'll be prompted to run a cloud fixity check & repair.

To demo the broken cloud file beforehand do this:
* go to console.cloud.google.com
* make sure you're logged in with your princeton account (check your avatar on the top right)
* select pulibrary-figgy-storage from the project drop-down
* search for and/or navigate to cloud storage
* select figgy-staging-preservation 
* filter to the ID of the resource to get into the right folder, then keep
    clicking through the paths until you see the file listed. Attempt to
    download and open it - it should be corrupt.

Hit enter in the terminal, refresh Figgy and continue when the cloud fixity says
it succeeded. Download the file from preservation storage again to show that
it's now repaired.

### Both Bad

You'll be prompted to run fixity checks on both cloud and local fixity. Hit
enter, look at the Resource or FileSet pages and it should show that both need
attention.
