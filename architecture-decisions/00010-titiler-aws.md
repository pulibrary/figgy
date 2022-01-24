# 10. TiTiler on AWS

Date: 2022-01-24

## Status

Accepted

## Context

We want to provide raster tile services to allow display of several rasters at
once without downloading all of the raster files. There are a few options for
implementation:

1. [TiTiler](https://devseed.com/titiler/) running on a VM.
1. [TiTiler](https://devseed.com/titiler/) running in AWS via lambdas.
1. [Geoserver
   WMTS](https://docs.geoserver.org/latest/en/user/services/wmts/webadmin.html)
1. [ArcGIS
   WMTS](https://enterprise.arcgis.com/en/server/latest/publish-services/windows/tutorial-creating-a-cached-map-service.htm)

We've had trouble with our Geoserver and ArcGIS implementations in the past. We
have experience running lambda-powered services with our IIIF service.

We expect there to be bursts of traffic - most of the time no users, but
occasionally a full class of users at once.

## Decisions

We're going to host TiTiler via AWS Lambda, Cloudfront, and AWS API Gateway.
This is a similar setup to our IIIF service and provides maximum uptime and
automatic scaling for bursts of traffic. We only have to pay for the access when
it's being used.

Our deployment will be scripted and hosted as a [Github
Project](https://github.com/pulibrary/titiler-aws).

## Consequences

1. This is another application to support.
1. The software's written in Python - if we need customizations or adjustments
   they'll have to be done in Python, which our team doesn't use.
1. The costs scale directly with traffic with no upper limit. However, our
   experience with the IIIF lambda server has shown this to not to be a problem.
