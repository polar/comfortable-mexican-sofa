Cms::Revision.blueprint do
end

Cms::Revision.blueprint(:layout) do
  data {
    {
        'content' => 'revision {{cms:page:default_page_text}}',
        'css'     => 'revision css',
        'js'      => 'revision js'
    }
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
    }
  }
end

Cms::Revision.blueprint(:snippet) do
  data {
    {
        'content' => 'revision content'
    }
  }
end
