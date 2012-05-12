Cms::File.blueprint do
  file_file_name { "sample.jpg "}
  file_content_type { "image/jpeg" }
  file_file_size { 20099 }
  description { "Description" }
end

Cms::File.blueprint(:default) do
  file_file_name { "sample.jpg" }
  file_content_type { "image/jpeg" }
  file_file_size { 20099 }
  description { "Description" }
end