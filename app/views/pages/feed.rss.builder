xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{Settings.site.name} #{@document.permalink.upcase}"
    xml.description @document.summary.blank? ? @document.summary : Settings.site.description
    xml.link document_url(@document) + '.rss'

    for document in @document.children.with_state(:published)
      xml.item do
        xml.title document.title
        xml.description document.summary
        xml.pubDate document.published_at.to_s(:rfc822)
        xml.link document_url(document)
      end
    end
  end
end
