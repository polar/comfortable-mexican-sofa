
Cms::Block.blueprint do
end

Cms::Block.blueprint(:default_field_text) do
  identifier { "default_field_text" }
  content { "default_field_text_content" }
end

Cms::Block.blueprint(:default_page_text) do
  identifier { "default_page_text" }
  content { "default_page_text_content_a\n{{cms:snippet:default}}\ndefault_page_text_content_b" }
end
