class FacilitiesController < ApplicationController
  allow_unauthenticated_access

  def index
    @criteria = Search::Criteria.from_params(params)
    @result = Search::FacilitySearch.new.call(@criteria)
    @features = Feature.ordered
  end

  def show
    @facility = Facility.includes(:features).find(params[:id])
    @recommendations = Recommendations::SimilarFacilities.new(@facility).call
  end
end
