module ArticlesHelper
  def link_to_article(article, link_title = nil)
    link_title ||= article.title.html_safe
    link_to link_title, article_show_path(:openurl => article.src['openUrl'])
  end
end
