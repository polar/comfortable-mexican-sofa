Cms::Layout.blueprint do
  parent { nil }
end

Cms::Layout.blueprint(:default) do
  label { "Default Layout" }
  identifier { "default" }
  content { "{{cms:field:default_field_text:text}}
layout_content_a
{{cms:page:default_page_text:text}}
layout_content_b
{{cms:snippet:default}}
layout_content_c"
  }
  css { "default_css" }
  js { "default_js" }
end

Cms::Layout.blueprint(:nested) do
  label { "Nested Layout" }
  identifier { "nested" }
  content {
    "{{cms:page:header}}\n{{cms:page:content}}"
  }
  css { "nested_css" }
  js { "nested_js" }
  position { 0 }
end

Cms::Layout.blueprint(:child) do
  label { "Child Layout" }
  identifier { "child" }
  content {
    "{{cms:page:left_column}}\n{{cms:page:right_column}}"
  }
  css { "child_css" }
  js { "child_js" }
end