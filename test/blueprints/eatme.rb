Cms::Eatme.blueprint do

end

Cms::Eatme.blueprint(:parent) do
  name { "parent" }
end

Cms::Eatme.blueprint(:child) do
  name { "child" }
end