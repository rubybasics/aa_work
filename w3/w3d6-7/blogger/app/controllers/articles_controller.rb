class ArticlesController < ApplicationController
  def show
    @articles = Article.all
  end
end
