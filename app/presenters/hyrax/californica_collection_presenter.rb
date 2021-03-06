# frozen_string_literal: true
module Hyrax
  class CalifornicaCollectionPresenter < Hyrax::CollectionPresenter
    # Terms is the list of fields displayed by
    # app/views/collections/_show_descriptions.html.erb
    def self.terms
      [
        :alternative_title,
        :architect,
        :ark,
        :author,
        :binding_note,
        :based_near,
        :calligrapher,
        :creator,
        :commentator,
        :contributor,
        :caption,
        :collation,
        :colophon,
        :composer,
        :condition_note,
        :contents_note,
        :date_created,
        :dimensions,
        :editor,
        :engraver,
        :extent,
        :featured_image,
        :finding_aid_url,
        :foliation,
        :funding_note,
        :genre,
        :iiif_manifest_url,
        :iiif_range,
        :illustrations_note,
        :illustrator,
        :iiif_viewing_hint,
        :identifier,
        :illuminator,
        :keyword,
        :location,
        :language,
        :latitude,
        :license,
        :longitude,
        :local_identifier,
        :lyricist,
        :masthead_parameters,
        :medium,
        :named_subject,
        :normalized_date,
        :note,
        :opac_url,
        :page_layout,
        :photographer,
        :place_of_origin,
        :printmaker,
        :provenance,
        :publisher,
        :related_url,
        :representative_image,
        :repository,
        :rights_country,
        :rights_holder,
        # :local_rights_statement, # This invokes License renderer from hyrax gem
        :resource_type,
        :rubricator,
        :scribe,
        :services_contact,
        :size,
        :subject,
        :subject_geographic,
        :subject_temporal,
        :subject_topic,
        :support,
        :summary,
        :tagline,
        :thumbnail_link,
        :iiif_text_direction,
        :translator,
        :toc,
        :total_items,
        :uniform_title
      ]
    end
  end
end
