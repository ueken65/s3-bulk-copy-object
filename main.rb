#! /usr/bin/env ruby

require "dotenv"
require "aws-sdk-s3"
require "parallel"

Dotenv.load

pp ENV["ASSETS_HOST"]

list_file = ARGV.shift
fh = File.open(list_file)

puts Time.now.iso8601(6)

Parallel.each_with_index(fh.each_line, in_threads: 512) do |line, index|
  next unless line =~ /\.(?:webp|jpeg|jpg|gif|png)/
  next if line =~ /(?:_s10|_s180|_s240|_s320)\./
  path = line.chomp.sub(/.* /, "")
  ext = path.sub(/.*\./, "")
  s3 = Aws::S3::Client.new

  begin
    s3.copy_object(
      acl: "public-read",
      bucket: ENV["ASSETS_HOST"],
      copy_source: "/#{ENV['ASSETS_HOST']}/#{path}",
      key: path,
      content_type: "image/#{ext}",
      cache_control: "max-age=31536000",
      metadata_directive: "REPLACE"
    )
  rescue Aws::Errors::ServiceError => error
    pp [path, index, error]
  end

  pp [path, index, Time.now.iso8601(6)] if index%10000 == 0
end

puts Time.now.iso8601(6)
