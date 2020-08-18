output=`git diff --numstat --exit-code origin/main RELEASE_NOTES.md`
# there was no difference in the file
if [ $? -eq 0 ]
  then
    exit 1
fi
# there was a difference; make sure it was an addition
! echo $output | cut -c1 | grep 0
