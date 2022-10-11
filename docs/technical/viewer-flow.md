# Viewer Flow

The logic for determining which viewer screen to display to a user for a given
resource is complex. The workflow below attempts to summarize code split out in
various locations.

```mermaid
sequenceDiagram
  participant User
  participant iFrame
  participant Orangelight
  participant GraphQL
  participant Figgy
  User->>Orangelight: View Page
  Orangelight->>GraphQL: Request Resource
  alt READ true
    GraphQL->>Orangelight: Return ID
    Orangelight->>iFrame: Render viewer iFrame
    iFrame->>User: UV Appears
  else READ false DISCOVER true
    GraphQL->>Orangelight: Return ID
    Orangelight->>iFrame: Render viewer iFrame
    iFrame->>Figgy: Check Manifest Status
    alt Logged In
      Figgy->>iFrame: HTTP 401
      iFrame->>User: Buncha CDL stuff or nothing
    else Not Logged In
      Figgy->>iFrame: HTTP 401
      iFrame->>User: Big Login Button
    end
  else READ false DISCOVER false
    GraphQL->>Orangelight: Return empty response
    Orangelight->>User: Nothing.
  end
    
```

## GraphQL Version

```mermaid
sequenceDiagram
  participant User
  participant Pulfalight
  participant GraphQL
  User->>Pulfalight: View Page
  Pulfalight->>GraphQL: Request Resource
  alt READ true
    GraphQL->>Pulfalight: status authorized, HTML
    Pulfalight->>User: Render HTML (UV in iFrame) or Link (Download Content)
  else READ false DISCOVER true
    alt Logged In
      GraphQL->>Pulfalight: status unauthorized, no HTML
      Pulfalight->>User: Nothing
    else Not Logged in
      GraphQL->>Pulfalight: status unauthenticated, no HTML
      Pulfalight->>User: Yellow login box
    end
  else READ false DISCOVER false
    GraphQL->>Pulfalight: empty response
    Pulfalight->>User: Nothing
  end
    
```
