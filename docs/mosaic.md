## Ingest / Model Structure

### Scanned maps with associated rasters

Bulk ingest structure - resource types to create are in parenthesis.

1. :file_folder: Ingestdir
   1. :file_folder: [bibid] (ScannedMap (i.e. a mapset))
      1. :file_folder: [bibid2] (ScannedMap)
         1. :file_folder: Raster (RasterResource)
             1. :memo: Sheet1_cropped.tif (FileSet)
                 * metadata property service_targets: mosaic
             2. :memo: Sheet1.tif (FileSet)
         2. :memo: Sheet1.tif (FileSet)
       2. :file_folder: [bibid3] (ScannedMap)
          1. :file_folder: Raster (RasterResource)
             1. :memo: Sheet2_cropped.tif (FileSet)
                 * metadata property service_targets: mosaic
             2. :memo: Sheet2.tif (a FileSet)
          2. :memo: sheet2.tif

### Raster sets

1. :file_folder: Ingestdir
    1. :file_folder: [bibid] (RasterResource (i.e. a RasterSet))
        1. :file_folder: Raster (RasterResource)
            1. :memo: Sheet1.tif (FileSet)
                * metadata property service_targets: mosaic
        1. :file_folder: Raster (RasterResource)
            1. :memo: Sheet2.tif (a FileSet)
                * metadata property service_targets: mosaic
