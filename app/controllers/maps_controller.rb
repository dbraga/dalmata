class MapsController < ApplicationController
	
	def index
		@results = Map.results(params[:query], params[:rows], params[:title], params[:snippet]).html_safe
	end

end
