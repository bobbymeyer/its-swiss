class PagesController < ApplicationController
  def show
    flash.now[:notice] = params[:notice] if params[:notice]
    flash.now[:alert] = params[:alert] if params[:alert]
  end

  def other; end

  def bare; end
end
