GitToS3
============  

deploy file to s3. 

Notice:
============

if filename contains utf-8 characters, please add  

quotepath=false  

to your  project/.git/config    

in the [core]  section


Requirement:
============

* s3

Usage:
============
setup config.json  (see config.json.example)
deploy.rb   

* -v verbose
* --dryrun   
*  -f  config file name

S3  Bucket  Structure
=================  

/- deploy_bucket ( contain version.s3)

/- publish_bucket ( no version.s3) 

Otherwise, you can keep version.s3, and make it private.

