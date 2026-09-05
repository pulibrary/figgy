# Relationships

Here we document some known resource relationships and structures for certain use cases.

## Book w/ Pages

```mermaid
---
config:
  flowchart: 
    curve: stepAfter
  
---
flowchart LR
   SR["ScannedResource<br>'Awesome Thing'"]
   FS["FileSet<br>'Page 36'"]
   fileMetadata[ ]:::empty
   original["FileMetadata<br>'page36.tif'"]
   derivative["FileMetadata<br>'page36-derivative.tif'"]
   SR-->FS
   FS---fileMetadata
   fileMetadata-->original
   fileMetadata-->derivative
   classDef empty width: 0, height: 0
```

## Multi-Spectral Imaging (Current State)

We don't like this because we currently aren't associating the page images from one resource to another.

```mermaid
---
config:
  flowchart: 
    curve: stepAfter
  
---
flowchart LR
   SR["ScannedResource<br>'Awesome Thing'"]
   MSI["ScannedResource<br>'MSI for Awesome Thing'"]
   MSImemberIds[ ]:::empty
   FS["FileSet<br>'Page 36'"]
   fileMetadata[ ]:::empty
   original["FileMetadata<br>'page36.tif'"]
   derivative["FileMetadata<br>'page36-derivative.tif'"]
   MSIFS["FileSet<br>'Page 36 UV'"]
   fileMetadata2[ ]:::empty
   fileMetadata3[ ]:::empty
   MSIFSoriginal["FileMetadata<br>'page36-uv.tif'"]
   MSIFSderivative["FileMetadata<br>'page36-uv-derivative.tif'"]
   MSIFS2["FileSet<br>'Page 36 IR'"]
   MSIFS2original["FileMetadata<br>'page36-ir.tif'"]
   MSIFS2derivative["FileMetadata<br>'page36-ir-derivative.tif'"]
   SR-->FS
   FS---fileMetadata
   fileMetadata-->original
   fileMetadata-->derivative

   MSI---MSImemberIds
   MSImemberIds-->MSIFS
   MSImemberIds-->MSIFS2
   MSIFS---fileMetadata2
   fileMetadata2-->MSIFSoriginal
   fileMetadata2-->MSIFSderivative
   MSIFS2---fileMetadata3
   fileMetadata3-->MSIFS2original
   fileMetadata3-->MSIFS2derivative

   classDef empty width: 0, height: 0, overflow: hidden
```
```
