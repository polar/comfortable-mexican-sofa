Cms::Site.blueprint do
  is_mirrored { false }
end

Cms::Site.blueprint(:default) do
  label { "Default Site" }
  identifier { "default-site" }
  hostname { "test.host" }
end