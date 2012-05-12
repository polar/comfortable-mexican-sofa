Cms::Page.blueprint do
end

Cms::Page.blueprint(:default)  do
  identifier { "default page" }
  label { "Default Page" }
  slug { "default-page" }
  full_path { '/' }
  is_published { true }
  content { "
layout_content_a
default_page_text_content_a
default_snippet_content
default_page_text_content_b
layout_content_b
default_snippet_content
layout_content_c"
  }
end

Cms::Page.blueprint(:child)  do
  identifier { "child page" }
  label { "Child Page" }
  slug { "child-page"}
  full_path { '/child-page' }
  is_published { true }
  content { "

layout_content_a

layout_content_b
default_snippet_content
layout_content_c"
  }
end
