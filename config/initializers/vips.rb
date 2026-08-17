# Enable the external loaders we depend on for Figgy.
# See https://www.libvips.org/2022/05/28/What's-new-in-8.13.html and https://github.com/libvips/ruby-vips/pull/382
Rails.application.config.after_initialize do
  Vips.block("VipsForeignLoadPdf", false)
  Vips.block("VipsForeignLoadMagick7File", false)
  Vips.block("VipsForeignLoadMagick7", false)
  Vips.block("VipsForeignLoadMagick", false)
end
