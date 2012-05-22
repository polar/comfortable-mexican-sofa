Cms::Site.blueprint do
  is_mirrored { false }
end

Cms::Site.blueprint(:default) do
  label { "Default Site" }
  identifier { "default-site" }
  hostname { "test.host" }
end

Cms::Site.blueprint(:with_path) do
  label { "With Path Site" }
  identifier { "with-path-site" }
  hostname { "test.host" }
  path { "en/site" }
end