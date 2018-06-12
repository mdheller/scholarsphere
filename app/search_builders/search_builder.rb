# frozen_string_literal: true

class SearchBuilder < Sufia::CatalogSearchBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder

  self.default_processor_chain += [
    :add_access_controls_to_solr_params,
    :add_advanced_parse_q_to_solr,
    :show_works_or_works_that_contain_files
  ]

  # @note Overrides Sufia with a later Hyrax version to correct full-text searching.
  # show both works that match the query and works that contain files that match the query
  def show_works_or_works_that_contain_files(solr_parameters)
    return if blacklight_params[:q].blank? || blacklight_params[:search_field] != 'all_fields'
    solr_parameters[:user_query] = blacklight_params[:q]
    solr_parameters[:q] = new_query
    solr_parameters[:defType] = 'lucene'
  end

  # TODO: Remove this once projecthydra-labs/curation_concerns#724 is approved
  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    return [] if ability.current_user.administrator?
    super
  end

  # the {!lucene} gives us the OR syntax
  def new_query
    "{!lucene}#{interal_query(dismax_query)} #{interal_query(join_for_works_from_files)} #{interal_query(join_for_works_from_agents)}"
  end

  # join from file id to work relationship solrized file_set_ids_ssim
  def join_for_works_from_agents
    "{!join from=#{ActiveFedora.id_field} to=creator_list_ssim}#{dismax_query}"
  end
end