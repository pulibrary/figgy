## Checking SVN jobs

Figgy DAOs are added to EAD in PULFA weekly, on Monday mornings.  This operation is performed by the `figgysvn` user.  If DAOs from Figgy are failing to appear in the EAD in Pulfa, success or failure of the job can be verified by checking the SVN logs on the lib-svn server for references to the Figgy user, output similar to the following:

```bash
...
13210 2020-06-23T11:31:55.594433Z 172.20.210.36 figgysvn libsvn commit r19687
13219 2020-06-23T11:32:19.809517Z 172.20.210.36 - libsvn open 2 cap=(edit-pipeline svndiff1 accepts-svndiff2 absent-entries depth mergeinfo log-revprops) /trunk/eads SVN/1.14.0%20(x86_64-apple-darwin19.4.0) -
13219 2020-06-23T11:32:19.983464Z 172.20.210.36 figgysvn libsvn commit r19688
...
```

## Checking out a fresh copy of the repository

In the event that a fresh copy of the Pulfa SVN repository is needed on Figgy, complete the following steps as the deploy user:

```bash
cd $SVN_DIR

# Move the existing repository out of the path
mv pulfa pulfa_something_deprecated

# Create a fresh checkout
svn checkout --username $SVN_USER --password $SVN_PASS $SVN_URL pulfa
```

## Running the export

To run the export outside of the schedule, run the following on figgy1 as the deploy user:

```bash
export PATH="/usr/local/bin/:$PATH" && cd /opt/figgy/releases/$RELEASE && RAILS_ENV=production bundle exec rake export:pulfa
```

Replace `$RELEASE` with the name of the newest directory (newest Figgy release) at `/opt/figgy/releases`.
