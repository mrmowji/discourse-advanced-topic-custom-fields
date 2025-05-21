# frozen_string_literal: true

# name: discourse-topic-priority
# about: Adds the ability to set a priority for topics.
# version: 1.0
# authors: Mojtaba Javan
# url: https://github.com/mrmowji/discourse-topic-priority

# Forked from https://github.com/pavilionedu/discourse-topic-custom-fields

enabled_site_setting :topic_priority_enabled
enabled_site_setting :topic_priority_field_categories
register_asset "stylesheets/common.scss"

after_initialize do
  module ::TopicCustomFields
    FIELD_NAME = SiteSetting.topic_priority_field_name
    FIELD_TYPE = SiteSetting.topic_priority_field_type
    CATEGORIES = Array(SiteSetting.topic_priority_field_categories)
      .reject { |c| c.blank? }
      .map(&:to_i)
  end

  register_topic_custom_field_type(
    TopicCustomFields::FIELD_NAME,
    TopicCustomFields::FIELD_TYPE.to_sym,
  )

  # Getter method
  add_to_class(:topic, TopicCustomFields::FIELD_NAME.to_sym) do
    if !custom_fields[TopicCustomFields::FIELD_NAME].nil?
      custom_fields[TopicCustomFields::FIELD_NAME]
    else
      0
    end
  end

  # Setter method
  add_to_class(:topic, "#{TopicCustomFields::FIELD_NAME}=") do |value|
    custom_fields[TopicCustomFields::FIELD_NAME] = value
  end

  on(:topic_created) do |topic, opts, user|
    allowed_groups = SiteSetting.topic_priority_field_allowed_groups.present? ? 
      SiteSetting.topic_priority_field_allowed_groups.split('|').map { |g| g.strip.to_i } : 
      []
    user_groups = user.groups.map(&:id)
    can_edit = (user_groups & allowed_groups).any?
    if can_edit
      topic.send(
        "#{TopicCustomFields::FIELD_NAME}=".to_sym,
        opts[TopicCustomFields::FIELD_NAME.to_sym],
      )
      topic.save!
    end
  end

  PostRevisor.track_topic_field(TopicCustomFields::FIELD_NAME.to_sym) do |tc, value|
    allowed_groups = SiteSetting.topic_priority_field_allowed_groups.present? ? 
      SiteSetting.topic_priority_field_allowed_groups.split('|').map { |g| g.strip.to_i } : 
      []
    user_groups = tc.user.groups.map(&:id)
    can_edit = (user_groups & allowed_groups).any?
    if can_edit
      tc.record_change(
        TopicCustomFields::FIELD_NAME,
        tc.topic.send(TopicCustomFields::FIELD_NAME),
        value,
      )
      tc.topic.send("#{TopicCustomFields::FIELD_NAME}=".to_sym, value.present? ? value : nil)
    end
  end

  # Send our field to the client, along with the other topic fields.
  add_to_serializer(:topic_view, TopicCustomFields::FIELD_NAME.to_sym) do
    object.topic.send(TopicCustomFields::FIELD_NAME)
  end

  add_preloaded_topic_list_custom_field(TopicCustomFields::FIELD_NAME)

  add_to_serializer(:topic_list_item, TopicCustomFields::FIELD_NAME.to_sym) do
    object.send(TopicCustomFields::FIELD_NAME)
  end

  add_to_class(:topic_query, :listable_topic_custom_fields) do
    super() + [TopicCustomFields::FIELD_NAME]
  end
  
  if TopicQuery.respond_to?(:results_filter_callbacks)
    TopicQuery.results_filter_callbacks << lambda do |_type, result, _user, options|
      if options[:order] == TopicCustomFields::FIELD_NAME
        sort_dir = (options[:ascending] == "true") ? "ASC" : "DESC"
        field_name = TopicCustomFields::FIELD_NAME
        result = result.joins(
          "LEFT JOIN topic_custom_fields AS tcf ON tcf.topic_id = topics.id AND tcf.name = '#{field_name}'"
        ).reorder(
          "COALESCE(NULLIF(tcf.value, ''), '0')::int #{sort_dir}, topics.bumped_at DESC"
        )
      end
      result
    end
  end
end
