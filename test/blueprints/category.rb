Cms::Category.blueprint do
end


Cms::Category.blueprint(:default) do
  label { "default" }
  categorized_type { "Cms::File" }
end