## Ingest / Model Structure

### Scanned maps with associated rasters

Bulk ingest structure - resource types to create are in parenthesis.

1. Ingestdir
   1. [bibid] (ScannedMap (i.e. a mapset))
       1. [bibid2] (ScannedMap)
            1. Raster (RasterResource)
                1. Sheet1_cropped.tif (FileSet)
                    * metadata property service_targets: mosaic
                2. Sheet1.tif (FileSet)
            2. Sheet1.tif (FileSet)
        2. [bibid3] (ScannedMap)
            3. Raster (RasterResource)
                3. Sheet2_cropped.tif (FileSet)
                    * metadata property service_targets: mosaic
                4. Sheet2.tif (a FileSet)
            4. sheet2.tif

### Raster sets

1. Ingestdir
    1. [bibid] (RasterResource (i.e. a RasterSet))
        1. Raster (RasterResource)
            1. Sheet1.tif (FileSet)
                * metadata property service_targets: mosaic
        1. Raster (RasterResource)
            1. Sheet2.tif (a FileSet)
                * metadata property service_targets: mosaic
