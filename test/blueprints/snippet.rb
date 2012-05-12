Cms::Snippet.blueprint do
end

Cms::Snippet.blueprint(:default) do
  label { "Default Snippet" }
  identifier { "default" }
  content { "default_snippet_content" }
  position { 0 }
end