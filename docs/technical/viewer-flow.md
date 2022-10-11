# Viewer Flow

The logic for determining which viewer screen to display to a user for a given
resource is complex. The workflow below attempts to summarize code split out in
various locations.

```mermaid
sequenceDiagram
  participant User
  participant Orangelight
  participant iFrame
  participant GraphQL
  participant Figgy
  User->>Orangelight: View Page
  Orangelight->>GraphQL: Request Resource
  alt DISCOVER true
    GraphQL-->>Orangelight: Return ID
    Orangelight-->>iFrame: Render viewer iFrame
    iFrame->>Figgy: Check Manifest Status
    Note over iFrame,Figgy: Javascript Call within iFrame
    alt READ true
      Figgy-->>iFrame: HTTP 200
      iFrame-->>User: Render Universal Viewer
    else Logged In
      Figgy-->>iFrame: HTTP 401
      Note over iFrame,Figgy: JS redirects to /viewer/auth
      alt CDL Eligible
        iFrame-->>User: CDL Checkout Screen
      end
    else Not Logged In
      Figgy-->>iFrame: HTTP 401
      Note over iFrame,Figgy: JS redirects to /viewer/auth
      %% We could put click-throughs here...?
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

## GraphQL Version

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
      %% This is where we'd have to handle CDL or click-through
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
