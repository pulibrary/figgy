# frozen_string_literal: true
RSpec.shared_context "Tika output" do
  let(:tika_tiff_output) { '{"Bits Per Sample":"8 8 8 bits/component/pixel","Compression":"Uncompressed","Content-Length":"196882","Content-Type":"image/tiff","Creation-Date":"2014-12-03T12:40:50","Date/Time":"2014:12:03 12:40:50","Document Name":"color_200.tif","File Modified Date":"Thu Jul 13 17:34:57 PDT 2017","File Name":"example.tif20170713-88893-1cirjkm","File Size":"196882 bytes","Fill Order":"Normal","Image Height":"287 pixels","Image Width":"200 pixels","Inter Color Profile":"[560 bytes]","Last-Modified":"2014-12-03T12:40:50","Last-Save-Date":"2014-12-03T12:40:50","Make":"Phase One","Model":"P65+","Orientation":"Top, left side (Horizontal / normal)","Photometric Interpretation":"RGB","Planar Configuration":"Chunky (contiguous for each subsampling pixel)","Primary Chromaticities":"2748779008/4294967295 1417339264/4294967295 1288490240/4294967295 2576980480/4294967295 644245120/4294967295 257698032/4294967295","Resolution Unit":"Inch","Rows Per Strip":"13 rows/strip","Samples Per Pixel":"3 samples/pixel","Software":"Adobe Photoshop CS5.1 Macintosh","Strip Byte Counts":"7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 7800 600 bytes","Strip Offsets":"[23 longs]","Unknown tag (0x0129)":"0 1","Unknown tag (0x02bc)":"[14622 shorts]","Unknown tag (0x8649)":"[8822 shorts]","White Point":"1343036288/4294967295 1413044224/4294967295","X Resolution":"1120 dots per inch","X-Parsed-By":["org.apache.tika.parser.DefaultParser","org.apache.tika.parser.image.TiffParser"],"Y Resolution":"1120 dots per inch","date":"2014-12-03T12:40:50","dcterms:created":"2014-12-03T12:40:50","dcterms:modified":"2014-12-03T12:40:50","meta:creation-date":"2014-12-03T12:40:50","meta:save-date":"2014-12-03T12:40:50","modified":"2014-12-03T12:40:50","resourceName":"example.tif20170713-88893-1cirjkm","tiff:BitsPerSample":"8","tiff:ImageLength":"287","tiff:ImageWidth":"200","tiff:Make":"Phase One","tiff:Model":"P65+","tiff:Orientation":"1","tiff:ResolutionUnit":"Inch","tiff:SamplesPerPixel":"3","tiff:Software":"Adobe Photoshop CS5.1 Macintosh","tiff:XResolution":"1120.0","tiff:YResolution":"1120.0"}' }
  let(:tika_xml_output) { '{"Content-Length":"38294","Content-Type":"application/xml","X-Parsed-By":["org.apache.tika.parser.DefaultParser","org.apache.tika.parser.xml.DcXMLParser"],"resourceName":"example.xml"}' }
  let(:tika_output) { tika_tiff_output }
  let(:im_output) do
    {"name"=>nil,
     "baseName"=>"mini_magick20171116-25665-1emiv0p.tif",
     "format"=>"TIFF",
     "formatDescription"=>"TIFF",
     "mimeType"=>"image/tiff",
     "class"=>"DirectClass",
     "geometry"=>{"width"=>200, "height"=>287, "x"=>0, "y"=>0},
     "resolution"=>{"x"=>1120, "y"=>1120},
     "printSize"=>{"x"=>0.17857142857142858, "y"=>0.25625},
     "units"=>"PixelsPerInch",
     "type"=>"TrueColor",
     "endianess"=>"Undefined",
     "colorspace"=>"sRGB",
     "depth"=>8,
     "baseDepth"=>8,
     "channelDepth"=>{"red"=>8, "green"=>8, "blue"=>1},
     "pixels"=>172200,
     "imageStatistics"=>
    {"Overall"=>
     {"min"=>"14", "max"=>"220", "mean"=>"163.578", "standardDeviation"=>"42.5", "kurtosis"=>"1.45214", "skewness"=>"-1.50387"}},
    "channelStatistics"=>
     {"Red"=>
      {"min"=>"14", "max"=>"220", "mean"=>"179.794", "standardDeviation"=>"41.4217", "kurtosis"=>"3.83533", "skewness"=>"-2.1826"},
        "Green"=>
      {"min"=>"14", "max"=>"209", "mean"=>"166.2", "standardDeviation"=>"41.8122", "kurtosis"=>"2.05521", "skewness"=>"-1.80793"},
        "Blue"=>
      {"min"=>"14", "max"=>"183", "mean"=>"144.74", "standardDeviation"=>"36.4706", "kurtosis"=>"1.35996", "skewness"=>"-1.62255"}},
     "renderingIntent"=>"Perceptual",
     "gamma"=>0.454545,
     "chromaticity"=>
      {"redPrimary"=>{"x"=>0.64, "y"=>0.33},
       "greenPrimary"=>{"x"=>0.3, "y"=>0.6},
       "bluePrimary"=>{"x"=>0.15, "y"=>0.06},
       "whitePrimary"=>{"x"=>0.3127, "y"=>0.329}},
      "matteColor"=>"#BDBDBD",
      "backgroundColor"=>"#FFFFFF",
      "borderColor"=>"#DFDFDF",
      "transparentColor"=>"#00000000",
      "interlace"=>"None",
      "intensity"=>"Undefined",
      "compose"=>"Over",
      "pageGeometry"=>{"width"=>200, "height"=>287, "x"=>0, "y"=>0},
      "dispose"=>"Undefined",
      "iterations"=>0,
      "compression"=>"None",
      "orientation"=>"TopLeft",
      "properties"=>
      {"aux:Firmware"=>"P65+-M, Firmware: Main=5.2.2, Boot=2.2.8, FPGA=1.2.4, CPLD=5.0.1, PAVR=1.0.3, UIFC=1.0.1, TGEN=1.0",
       "aux:SerialNumber"=>"EJ021457",
       "date:create"=>"2017-11-16T10:01:23-08:00",
       "date:modify"=>"2017-11-16T10:01:23-08:00",
       "dc:format"=>"image/tiff",
       "icc:copyright"=>"Copyright 1999 Adobe Systems Incorporated",
       "icc:description"=>"Adobe RGB (1998)",
       "icc:manufacturer"=>"Adobe RGB (1998)",
       "icc:model"=>"Adobe RGB (1998)",
       "photoshop:ColorMode"=>"3",
       "photoshop:DateCreated"=>"2014-07-01T05:31:54-04:00",
       "photoshop:ICCProfile"=>"Adobe RGB (1998)",
       "photoshop:LegacyIPTCDigest"=>"0564A4B3A25278988BF921DEF4CCE6C9",
       "signature"=>"4db3d9e0828a91e7c38f7b10c14e93776b7c0c11bd953e438c2aabb5ee29c637",
       "tiff:alpha"=>"unspecified",
       "tiff:document"=>"color_200.tif",
       "tiff:endian"=>"lsb",
       "tiff:make"=>"Phase One",
       "tiff:model"=>"P65+",
       "tiff:photometric"=>"RGB",
       "tiff:rows-per-strip"=>"13",
       "tiff:software"=>"Adobe Photoshop CS5.1 Macintosh",
       "tiff:timestamp"=>"2014:12:03 12:40:50",
       "xmp:CreateDate"=>"2014-07-01T05:31:54",
       "xmp:CreatorTool"=>"Capture One 7 Macintosh",
       "xmp:MetadataDate"=>"2014-12-03T12:40:50-05:00",
       "xmp:ModifyDate"=>"2014-12-03T12:40:50-05:00",
       "xmpMM:DocumentID"=>"xmp.did:30B5279A0720681188C68005360BE60C",
       "xmpMM:InstanceID"=>"xmp.iid:30B5279A0720681188C68005360BE60C",
       "xmpMM:OriginalDocumentID"=>"xmp.did:30B5279A0720681188C68005360BE60C"},
       "profiles"=>{"8bim"=>{"length"=>"8822"}, "icc"=>{"length"=>"560"}, "xmp"=>{"length"=>"14622"}},
       "tainted"=>false,
       "filesize"=>"196882B",
       "numberPixels"=>"57400",
       "pixelsPerSecond"=>"0B",
       "userTime"=>"0.000u",
       "elapsedTime"=>"0:01.000",
       "version"=>"/usr/local/Cellar/imagemagick/7.0.6-4/share/doc/ImageMagick-7//index.html"}
  end
end

RSpec.configure do |config|
  config.include_context "Tika output"
  config.before(:each) do
    ruby_mock = instance_double(RubyTikaApp, to_json: tika_output)
    allow(RubyTikaApp).to receive(:new).and_return(ruby_mock)
    allow_any_instance_of(MiniMagick::Image).to receive(:data).and_return(im_output)
  end
end
