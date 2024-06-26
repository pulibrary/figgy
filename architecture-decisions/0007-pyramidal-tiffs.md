# 7. Pyramidal Tiffs & AWS Serverless Delivery

Date: 2020-03-27
Updated: 2022-10-31

## Status

Accepted

## Context

We have several TB of images to deliver through a IIIF service, more than any of
our physical boxes can currently hold all in one place. We have to pay
Kakadu a licensing fee in order to get acceptable tile delivery, and the
Cantaloupe server we use has been proven to be easily Denial-of-Service'd to the
point of freezing and no images being able to be served.

We will remedy this problem of scale by storing Pyramidal Tiffs in the cloud
which an AWS Lambda service (scale-able to at least a thousand simultaneous
request) will use to respond to IIIF image server requests, using Northwestern's
[serverless-iiif](https://github.com/nulib/serverless-iiif) project.

## Decisions

1. Generate Pyramidal tiffs using VIPS and upload them to an AWS bucket using
   `valkyrie-shrine`.
   * Any image greater than 15k pixels on the long-side will be downsized by
     half to reduce the derivative size and allow the image server to respond 
     in a reasonable amount of time.
2. Configure and deploy
   [serverless-iiif](https://github.com/nulib/serverless-iiif) to serve IIIF
   Image API requests using those pyramidal tiffs.
3. Configure an Amazon CloudFront cache in front of the lambda to automatically 
   cache tiles and info.jsons for one year.

## Consequences

1. We'll have to pay by request. However, numbers from Northwestern have 
   shown that this is extremely affordable. The price should be roughly
   $0.01/thousand requests/month.
2. Our scrolls have a little less zoom-ability due to the requirement of
   shrinking them by half. However, after optimization, testing has shown this to   be minimal and the quality sufficient.
3. We'll have to regenerate pyramidals for all of our FileSets. Fortunately we
   can do this in the background, allowing the system to fall back to Cantaloupe
   if a pyramidal has not yet been generated.
4. The tiles generated from this process have better accuracy than those
   generated by Cantaloupe - for a long time our image servers (both Cantaloupe
   and Loris) have been serving up highly saturated versions - this does not.
