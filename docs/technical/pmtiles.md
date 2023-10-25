# Architecture of PMTiles functionality

We generate vector derivatives in [PMTiles format](https://github.com/protomaps/PMTiles)
and upload to Amazon S3. The ACL for these is set as "public" or "non-public"
based on the visibility of the parent VectorResource. An AWS CloudFront distribution
serves requests to public data for users both within and outside of Princeton network
IP ranges. A second AWS CloudFront distribution will serve requests to public and
restricted data only for users within Princeton network IP ranges.

For deployment, we use this [AWS CDK Project](https://github.com/pulibrary/geoservices-aws).

## Creating new vector FileSet

```mermaid
flowchart
    VectorResource --> A
    VectorResource -.-|visibility| G
    A[Vector FileSet] --> B
    B(Create Derivatives)
    B -->|VIPS| D[Thumbnail]
     B -->|Tippecanoe| E
    E[PMTiles] --> F(Upload to S3)
    F --> G
    G(Update ACL)
    G --> I[public]
    G --> J[not-public]
```

## Requesting data from public CloudFront distribution

```mermaid
sequenceDiagram
    User->>CloudFront: public data request
    CloudFront->>S3: can access?
    S3-->>CloudFront: yes
    CloudFront->>S3: send data
    S3-->>CloudFront: [data]
    CloudFront-->>User: [data]
    User->>CloudFront: restricted data request
    CloudFront->>S3: can access?
    S3--xCloudFront: no
    CloudFront-->>User: 403
```

## Requesting data from restricted CloudFront distribution

- The restricted distribution is connected to a Web Application Firewall to filter requests by IP
address.
- To update the list of approved IP addresses and ranges, deploy the CDK geodata
stack. The
[script](https://github.com/pulibrary/geoservices-aws/blob/main/helpers/ip_list.py) will resolve the GlobalProtect FQDNs and send the updated list to the WAF.

```mermaid
sequenceDiagram
    User->>CloudFront: data request
    CloudFront->>WAF: Is in IP range?
    WAF--xCloudFront: No
    CloudFront-->>User: 403
    User->>CloudFront: public data request
    CloudFront->>WAF: Is in IP range?
    WAF-->>CloudFront: yes
    CloudFront->>S3: can access?
    S3-->>CloudFront: yes
    CloudFront ->>S3: send data
    S3-->>CloudFront: [data]
    CloudFront-->>User: [data]
    User->>CloudFront: restricted data request
    CloudFront->>WAF: Is in IP range?
    WAF-->>CloudFront: Yes
    CloudFront->>S3: can access?
    S3-->>CloudFront: yes
    CloudFront ->>S3: send data
    S3-->>CloudFront: [data]
    CloudFront-->>User: [data]
```
