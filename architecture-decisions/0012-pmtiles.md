# 10. PMTiles for Vector Derivatives

Date: 2023-10-24

## Status

Accepted

## Context

We have had trouble with the stability and complexity of our GeoServer instance
and want to move to a simpler cloud-native platform. We have had success with
using Cloud Optimized GeoTIFFs with TiTiler running in AWS lambda and would like to
do something analogous for vector data.

## Decisions

1. We're going to generate vector derivatives in [PMTiles
format](https://github.com/protomaps/PMTiles) and upload those to Amazon S3. The
ACL for these object will be set as "public" or "non-public" based on the
visibility of the parent VectorResource.
1. We will store the PMTiles files in S3 rather than locally for several
   reasons:
    - Figgy's download controller does not handle HTTP range requests, nor does
    Rails provide functionality for this outside of ActiveStorage.
    - Decoupling Figgy from front-end discovery layers will help with
    reliability. If Figgy is down, the display of vector previews won't be
    affected.
    - A cached CloudFront distribution and S3 are more performant than serving
    data through Figgy. A single client connection to a dataset can make
    many requests per second and lag will be noticeable when rendering the tiles.
1. An AWS CloudFront distribution will serve requests to public
  data for users both within and outside of Princeton network IP ranges.
1. A second AWS CloudFront distribution will serve requests to public
  and restricted data only for users within Princeton network IP ranges.
1. We will add an OpenLayers-based viewer to our GeoBlacklight instance which
will make targeted http range requests to these data sets and efficiently render
the vector data on a basemap.
1. Our deployment will be scripted as an [AWS CDK Project](https://github.com/pulibrary/geoservices-aws).

## Consequences

1. This is more cloud-based infrastructure we'll have to support.
1. We will have to regenerate derivates for all Vector Resources.
1. The costs scale directly with traffic with no upper limit. However, our
   experience with similar services has shown this to not to be a problem.
1. Because the gateway IPs of the GlobalProtect VPN change periodically, the
   list of addresses that our CloudFront distribution uses to filter restricted
   content will also need to be refreshed.
