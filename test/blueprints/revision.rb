Cms::Revision.blueprint do
  record { nil }
  record_type { nil }
end

Cms::Revision.blueprint(:layout) do
  data {
    {
        'content' => 'revision {{cms:page:default_page_text}}',
        'css'     => 'revision css',
        'js'      => 'revision js'
    }.to_yaml.inspect
  }

end

Cms::Revision.blueprint(:page) do
  data {
    {
        'blocks_attributes' => [
            { 'identifier' => 'default_page_text',
              'content'    => 'revision page content' },
            { 'identifier' => 'default_field_text',
              'content'    => 'revision field content' }
        ]
    }.to_yaml.inspect
  }
end

Cms::Revision.blueprint(:snippet) do
  data {
    {
        'content' => 'revision content'
    }.to_yaml.inspect
  }
end
