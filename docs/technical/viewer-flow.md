# Viewer Flow

The logic for determining which viewer screen to display to a user for a given
resource is complex. The workflow below attempts to summarize code split out in
various locations.

## Orangelight

Orangelight renders the viewer iFrame as long as the GraphQL returns a manifest
to render. Logic from that point forward is up to Figgy.

```mermaid
sequenceDiagram
  participant User
  participant Orangelight
  participant iFrame
  participant GraphQL
  User->>Orangelight: View Page
  Orangelight->>GraphQL: resources_by_orangelight_id
  alt DISCOVER true
    GraphQL-->>Orangelight: Return manifest URLs
    Orangelight-->>iFrame: Render viewer iFrame
    iFrame->>GraphQL: Get resource, embed status, notice
    alt READ true
      GraphQL-->>iFrame: status authorized
      iFrame-->>User: Render Universal Viewer
    else Logged In
      GraphQL-->>iFrame: status unauthorized
      Note over iFrame,GraphQL: JS redirects to /viewer/auth
      alt CDL Eligible
        iFrame-->>User: CDL Checkout Screen
      else still no access
        iFrame-->>User: Blank screen :(
      end
    else Not Logged In
      GraphQL-->>iFrame: status unauthenticated
      Note over iFrame,GraphQL: JS redirects to /viewer/auth
      alt CDL Eligible
        iFrame-->>User: "Login to Digitally Check Out"
      else OARSC
        iFrame-->>User: "Please Contact Special Collections, Login"
      else
        iFrame-->>User: Big Login Button
      end
    end
  else DISCOVER false
    GraphQL-->>Orangelight: Return empty response
    Orangelight-->>User: Nothing.
  end

```

## Finding Aids

Finding Aids uses the GraphQL endpoint locally to see if it should render
anything, so that a blank screen or large login button never appears. Instead it
renders a little yellow login box informing users how to get access.

Finding Aids also needs support for rendering a button to download links for
content (zip files) - so instead of creating its own iFrame, it just renders
whatever Figgy asks it to render (either a link or an iFrame.)

```mermaid
sequenceDiagram
  participant User
  participant Pulfalight
  participant GraphQL
  User->>Pulfalight: View Page
  Pulfalight->>GraphQL: Request Resource
  alt READ true
    GraphQL-->>Pulfalight: status authorized, HTML
    Pulfalight-->>User: Render HTML (UV in iFrame) or Link (Download Content)
  else READ false DISCOVER true
    alt Logged In
      GraphQL-->>Pulfalight: status unauthorized, no HTML
      Pulfalight-->>User: Nothing
    else Not Logged in
      GraphQL-->>Pulfalight: status unauthenticated, no HTML
      Pulfalight-->>User: Yellow login box
      Note over Pulfalight,User: Login box text is in Pulfalight
    end
  else READ false DISCOVER false
    GraphQL-->>Pulfalight: empty response
    Pulfalight-->>User: Nothing
  end
    
```
